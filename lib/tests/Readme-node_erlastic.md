# About

Node library to make nodejs gen_server in Erlang/Elixir through Port connection.

# Port

`Port` allows to start operating system processes external to the Erlang VM and communicate with them via message passing.

It`s an interface that handles communication between erlang process and OS process

## Open a OS process

```elixir
port = Port.open({:spawn, "cat"}, [:binary])

port = Port.open({:spawn, "node file.js"}, [:binary,:exit_status, packet: 4, cd: "path/to/file"])
```

`:binary` Tells Elixir to handle messages from the port as binary data instead of lists (which is default).

`:exit_status`: Ensures the port sends a message when the external process exits

    - You’ll receive a message like: {:EXIT, port, status_code}.

`packet: n` Adds a n-byte length header to each message sent to/from the port.

    - Helps Elixir determine where a message ends.

- other options: are about setting up the execution context of the process (like cd: [working dir] or env: [env var]).

## Send it a message

```elixir
send(port, {self(), {:command, "hello"}})

send(port, {self(), {:command, :erlang.term_to_binary(4)}})
```

This tells the port: "send this string ("hello") as input to the external process (cat)".

`:command` is a special tag that the port understands — it translates this to standard input (stdin) of the OS process.

## receive a message

the port will send the connected process the following messages:

- {port, {:data, data}} - data sent by the port
- {port, :closed} - reply to the {pid, :close} message
- {port, :connected} - reply to the {pid, {:connect, new_pid}} message
- {:EXIT, port, reason} - exit signals in case the port crashes. If reason is not :normal, this message will only be received if the owner process is trapping exits

So to receive data we can write this code

```elixir
receive do
  {^port, {:data, data}} ->
    IO.puts("Got from cat: #{data}")
end
```

# node_erlastic

it's a GenServer in js:

```javascript
var log = require("@kbrw/node_erlastic").log;

require("@kbrw/node_erlastic").server(function (
  term,
  from,
  // current_amount: get initialized when the genServer got init and then send the first message
  // it's equivalent to genServer state
  initialState,
  done
) {
  // GenServer.call HelloPort, :hello
  // term: {"type":"Atom","value":"hello"}
  if (term == "hello") return done("reply", "Hello world !");
  if (term == "what") return done("reply", "What what ?");
  if (term == "kbrw") {
    if (!initialState) return done("reply", "You should init state first");
    const newAmount = initialState - 2;
    return done("reply", newAmount, newAmount);
  }

  // GenServer.cast HelloPort, {:kbrw, 2}
  // term: {"0":{"type":"Atom","value":"kbrw"},"1":2,"type":"Tuple","length":2,"value":{"0":{"type":"Atom","value":"kbrw"},"1":2}}
  // it returns the "GenServer" new state as second arg
  if (term[0] == "kbrw") return done("noreply", term[1]);

  throw new Error("unexpected request");
});
```

And we can communicate wih it through an elixir GenServer:

```elixir
defmodule HelloPort do
  use GenServer

  ## Client

  def start_link() do
    GenServer.start_link(__MODULE__, {"node hello.js", 0, cd: "./web"}, name: __MODULE__)
  end

  ## Server

  def init({cmd, port_initial_state, opts}) do
    port = Port.open({:spawn, '#{cmd}'}, [:binary, :exit_status, packet: 4] ++ opts)
    send(port, {self, {:command, :erlang.term_to_binary(port_initial_state)}})

    {:ok, port}
  end

  def handle_call(message, _reply_to, port) do
    send(port, {self, {:command, :erlang.term_to_binary(message)}})

    res =
      receive do
        {^port, {:data, b}} -> :erlang.binary_to_term(b)
      end

    {:reply, res, port}
  end

  def handle_cast({:kbrw, number}, port) do
    send(port, {self, {:command, :erlang.term_to_binary({:kbrw, number})}})

    {:noreply, port}
  end
end
```
