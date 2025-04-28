# Processes

## create a process

To create a process we can use `spawn`function

- It takes in argument a function and execute it in another process
- It returns the id of the process in which it got executed
- It ends the process just after finishing executing the function

## check process status

To check if a process is alive we can use the function

```elixir
Process.alive?(PID)
```

## kill a process

```elixir
Process.exit(pid, msg)
```

## see all running processes

```elixir
:erlang.processes()
```

## Processes communication

A process communicate with another process using two utilities

- `send` allows us to send a message to a process by using its `pid`
  - `send(pid, msg)`
- `receive` make the process listenning for any message
  - It stop listening once a message is processed (quid: you may wanna listen again at the end of each message processing)

### How it works?

- Each process has its own mailbox and if the process is not setup to receive them they will stay there
- To check the process mailbox we can use `Process.info(pid, :messages)`n

### Example

```elixir
def listen_in_new_process do
    spaw(fn -> listen() end)
end

defp listen do
    receive do
        {:msg_id, payload} -> IO.puts("We got a message #{:msg_id} with the payload #{inspect(payload)}")
        listen()
    end
end
```

## Linking prcesses

### Problem

Imagine that we created a process `p2`from a `p1` and we stored its id in a variable, with this we can manage the process

But if, for example `p1` crashed, we will lose the variable containing the `p2` id, so we will lose access to it and there is no way to stop it, so it will stay floated

### Solution?

The solution is creating a `linked processes` instead of simple processes, so:

- if any process crashes and restart, all the process that are linked will exit

## Monitoring processes

What if we wanna just monito a process and know for example if it's down without being linked to a process?

At that occasion we wanna create a process using `spawn_monitor`

In case that process crashes, the parent process will receive a message in its mailbox:

```elixir
{pid, _} = spawn_monitor(fn -> receive do msg -> msg end end)

Process.exit(pid, :exit)

Process.info(self, :messages)
#Output:
#{:messages,
# [
#   {:DOWN, Reference<0.4150647085.3596091393.200530>, :process, PID<0.200.0>, :exit}
# ]}
```

# GenServer

it is used to write stateful server processes, and it defines a set of functions that must be implemented, the most common are `init` `handle_call` `handle_cast` `handle_info`

it allows to execute instructions in a transaction

## Make a module genServer

To do this, the mosule should `use GenServer`

And now we can start our genServer by

```elixir
GenServer.start_link(ModuleToStart, initialState, name: :nameOfGenServerProcess)
```

- The name is used to get the pid of the process where it's running `GenServer.whereis(:nameOfGenServerProcess)`
- If the name is `__MODULE__`, then we can call ou GenServer by the moduleName like: `GenServer.call(Counter, :get)`
- The initial_state is get passed to `init` function that returns server state

## init function

When we call `GenServer.start_link(CartServer, initial_state)` the initial_state param got passed to `init` function so that it can modify it or not and at the end it should return the GenServer real initial state

```elixir
  @impl true
  def init(initial_state) do
    {:ok, %{cart: initial_state}}
  end

  # Or

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

```

## Get the state of our GenServer

```elixir
:sys.get_state(:nameOfGenServerProcess)
```

## Interacting with our genServer

For this we have two functions:

### handle_call

#### About

- is synchronous
- will respond with a `:reply`
- get triggered with `GenServer.call(Module, message)`

#### Signature

It takes 3 arguments:

- The first one is the `message` being called
- The second is about the `sender`, it's a tuple containing its `pid`, `reference`
- The third one is the genServer `current state`

It returns a tuple with:

- `:reply` atom
- The value to return to the sender
- The updated state

### handle_cast

#### About

- asynchronous
- just process the message we send and assume it was received
- get triggered with `GenServer.call(Module, {message_type, payload})`

#### Signature

It takes 2 arguments:

- The first one is a tuple with `message type` and a `payload`
- The second one is the genServer `current state`

It returns a tuple with:

- `:noreply` atom
- The new state

### handle_info

if we send a message using `send` the function `handle_info` gets triggered

## Quick Start

```elixir
defmodule Database do
  use GenServer

  ## Client

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get() do
    GenServer.call(__MODULE__, :msg)
  end

  def put() do
    GenServer.cast(__MODULE__, {:msg, :payload})
  end

  ## Server

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call(:msg, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:msg, _payload}, state) do
    {:noreply, state}
  end
end
```

#### Signature

it takes 2 arguments

- The message
- Current state

It returns a tuple with:

- `:noreply` atom
- The new state

# ETS table

## About

ETS is a special table to save and read data, super fast. It's used for caching, like keeping stuff ready to grab quickly.

Normally, if your GenServer wants to remember something, it keeps it in its own memory. But if lots of processes want to read that memory at the same time, the GenServer gets tired

So instead, we use ETS:

- Store info like `key-value` pairs (`"toy" => "who has it"`)
- ETS is in-memory: it doesn’t save to disk => super fast
- They are managed by the Erlang VM itself
- Let other process of your program read from it directly, without waiting

## Create ETS table

We can create an ETS table using:

```elixir
table = :ets.new(:table_name, [:set, :protected, :named_table])
```

### Arguments

Default option values are `[:set, :protected]`

Some options:

- table name: allow us to access the table (by adding `:named_table` option)
- options like:
  - `:named_table`: allows us to
  - `:set`: means each key is unique (no duplicates)
  - `:protected`: only owner process can write, all processes can read
  - `:public`: all processes can read and write
  - `:private` only owner process can read and write

## Access to ETS table

⚠️ If you try to read or write and you're not allowed, you'll get an `ArgumentError`

### Insert / update

```elixir
:ets.insert(:table_name, {:key, value})
```

### Read

```elixir
:ets.lookup(:table_name, :key)
```

### Read all

```elixir
:ets.tab2list(:table_name)
```

### Delete

```elixir
:ets.delete(:table_name, key)
```

# ETS and GenServer

Here’s what a GenServer might do with ETS:

- On init, it creates an ETS table.
- When you want to create a bucket, it adds a new entry to ETS.
- When a bucket dies, it removes that entry from ETS.

So ETS becomes your shared notebook 📒 that lots of GenServers and processes can peek into.

# Supervisors

- A supervisor is a process which supervises other processes
- It start, monitor and restart processes for us based on strategies we set
- It can supervise one or more process, genServer and other supervisors
- The managed processes are called `children`

## Defining Suprevisor children

We can create a list of supervisor's children in several ways/formats:

```elixir
children = [
    {MyGenServer, [module_start_link_arguments]},
    # The Counter is a child started via Counter.start_link(0)
    %{id: Counter, start: {Counter, :start_link, [0]}},
    #  no arguments are needed -> simply write the name of your module
    AnotherGenServer,
    MyProcess,
    MySupervisor,
    MyModule,
    ...
]
```

## Supervisor strategy

[See the doc](https://hexdocs.pm/elixir/Supervisor.html#module-strategies)

## Create a supervisor

There is 2 ways to start a supervisor either directly with a list of child specifications via `start_link/2` or by defining a module-based supervisor that implements the required callbacks

### Direct start

```elixir
children = [
  # The Counter is a child started via Counter.start_link(0)
  %{
    id: Counter,
    start: {Counter, :start_link, [0]}
  }
]

# Now we start the supervisor with the children and a strategy
{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one,name: supervisor_name)

# After started, we can query the supervisor for information
Supervisor.count_children(pid)
# => %{active: 1, specs: 1, supervisors: 0, workers: 1}
```

### Module based supervisor

Just like GenServer, the module should `use Supervisor`, and then we should implement its functions (`init`, `start_link`)

#### start_link function

The function start_link/0 allows you to launch your Supervisor

```elixir
def start_link do
  {:ok, _} = Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
end
```

#### init function

- This funtion called by the function Supervisor.start_link called previously.
- Inside this function we can add all our child processes that we want to start
- It should call the Supervisor's init/2 function as follows:

```elixir
def init(_init_args) do
    children = [
        MyGenServer,
        ...
    ]

    Supervisor.init(children, strategy: :one_for_one)
end
```

## List supervisor children

```elixir
Supervisor.which_children(:supervisor_name)
```

# Application

An Elixir application is a little program we can start, stop, and manage as a unit. It often contains one or more processes, like GenServers or Supervisors, that work together.

It define what modules to start and how they connect (via a supervision tree).

## Create an Application

```elixir
defmodule MyApp do
  use Application

  @impl true
  def start(_type, _args) do
    children = []
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

And in `mix.exs`

```elixir
def application do
  [
    mod: {TutoKbrwStack, []},
    extra_applications: [:logger],
  ]
end
```
