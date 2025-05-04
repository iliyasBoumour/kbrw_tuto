# Prerequisites

## Port

`Port` allows to start operating system processes external to the Erlang VM and communicate with them via message passing.

It`s an interface that handles communication between erlang process and OS process

### Open a OS process

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

### Send it a message

```elixir
send(port, {self(), {:command, "hello"}})

send(port, {self(), {:command, :erlang.term_to_binary(4)}})
```

This tells the port: "send this string ("hello") as input to the external process (cat)".

`:command` is a special tag that the port understands — it translates this to standard input (stdin) of the OS process.

### receive a message

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

## poolboy

`Poolboy` is an Elixir library for managing a pool of processes.
Why? Because spawning too many processes at once could crash your app or slow it down.

### Real-Life Analogy: Restaurant Kitchen

Imagine a busy restaurant:

- Customers place orders (React rendering requests)
- The kitchen has a limited number of chefs (workers)
- The restaurant manager (Poolboy) gives available chefs to customers
- If all chefs are busy, customers must wait or overflow happens

### How Poolboy Works Technically

1. You define a worker module (like a chef) — mast times is a GenServer.
2. You start a pool supervisor — the boss that manages many workers.
3. You use Pool.transaction(...) to borrow a worker, use it, and return it automatically.

### setup a pool

`Pool.child_spec/3` is a function that generates the config (child_spec) needed to start a pool of worker processes under a supervisor.

```elixir
children = :poolboy.child_spec(pool_name, [worker_module: module_name, size: pool_size, max_overflow: pool_overflow, name: {:local, pool}], arg_passed_to_worker)
```

Then we need to start them using a supervisor

```elixir
Supervisor.start_link(children, opts)
```

### Using a worker

for that we use `:poolboy.transaction` it allow us to asking the pool for a worker, and then doing something with it, and finally giving the worker back when done

```elixir
:poolboy.transaction(
  pool_name,
  fn worker -> GenServer.call(worker, {args}) end,
  timeout
)
```

this:

1. Borrows a worker from the pool (pool_name)
2. Sends it a message
3. Waits for the result
4. Returns the worker to the pool

# node_erlastic

It's a node library to make nodejs the same behavior as gen_server in Erlang/Elixir through Port connection.

It allows us to :

- decode and encode between Binary Erlang Term and javascript types
- create a simple Erlang port interface through a nodeJS Readable and Writable (Duplex)
- create a "gen_server style" handler to manage your port

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

# Reaxt

This module integrates React.js rendering inside an Elixir backend using:

- A Node.js process to render React components
- GenServers to manage worker processes
- Poolboy to manage a pool of these workers (to handle concurrent renders efficiently)

## Breaking down the code

It creates an application and by starting it, it launch a supervisor that starts a module that creates a set of pools,

```elixir
defmodule App do
  use Application
  def start(_,_) do
    result = Supervisor.start_link([App.PoolsSup], name: __MODULE__, strategy: :one_for_one)
    WebPack.Util.build_stats
    result
  end

  defmodule PoolsSup do
    use Supervisor
    def start_link(arg) do Supervisor.start_link(__MODULE__,arg, name: __MODULE__) end
    def init(_) do
      # Takes the js files from priv directory, and for each one it creates a pool and pass that file to its workers
      server_dir = "#{WebPack.Util.web_priv}/#{Application.get_env(:reaxt,:server_dir)}"
      server_files = Path.wildcard("#{server_dir}/*.js")
      Supervisor.init(
        for server<-server_files do
          pool = :"react_#{server |> Path.basename(".js") |> String.replace(~r/[0-9][a-z][A-Z]/,"_")}_pool"
          Pool.child_spec(pool,[worker_module: Reaxt,size: pool_size, max_overflow: pool_overflow, name: {:local,pool}], server)
        end, strategy: :one_for_one)
    end
  end
end
```

As we can see above, the worker is a module called `Reaxt`, let's break it down

```elixir
defmodule Reaxt do
  alias :poolboy, as: Pool
  require Logger

  def render_result(chunk,{module,submodule},data,timeout) do
    Pool.transaction(:"react_#{chunk}_pool",fn worker->
      GenServer.call(worker,{:render,module,submodule,data,timeout},timeout+100)
    end)
  end

  def reload do
    WebPack.Util.build_stats
    Supervisor.terminate_child(Reaxt.App, Reaxt.App.PoolsSup)
    Supervisor.restart_child(Reaxt.App, Reaxt.App.PoolsSup)
  end

  def start_link(server_path) do
    init = Poison.encode!(Application.get_env(:reaxt,:global_config,nil))
    Exos.Proc.start_link("node #{server_path}",init,[cd: '#{WebPack.Util.web_priv}'])
  end
end
```

Now with all our pools set up, we need to start reading the `js` files and then executing them inside our `nodejs` server and getting back the result and returning it to our user, so here is what's going on:

- This launches a `Node.js` server process from Elixir using Exos.Proc.
- Sends some initial config as JSON
- The node server can now render React!

## How it works

1. Webpack compiles your React app

- Reaxt assumes this app lives in web/ folder inside your project.
- web/components/\*.js → React components
- web/webpack.config.js → Webpack config for client-side

Webpack builds both:

- The server-side JS used to render React components in Node
- The client-side JS served to the browser

2. Request comes in

When a user visits the app in the browser

```elixir
get _ do
  conn = fetch_query_params(conn)

  render =
    Reaxt.render!(
      # look for the module ./app in the web/components folder
      :app,
      %{path: conn.request_path, cookies: conn.cookies, query: conn.params},
      30_000
    )

  send_resp(200,layout(render))
end
```

This Calls Reaxt.render!(:app, %{...}) to get the server-rendered React HTML in the format:

```elixir
%{
  html: "<body><p class=\"logged-in-user\">John Doe</p></body>",
  js_render: "(window.reaxt_render.apply(window,...",
  param: nil
}
```

Wraps it in HTML layout and sends it back to the browser

3. `Reaxt.render!(:app, %{...})`

- This says “Please render the React component/module in web/components/app.js, passing these props.”
- This calls `render_result(:server, :app, %{...}, timeout)`
- This calls the pool:

```elixir
Pool.transaction(:"react_server_pool", fn worker ->
  GenServer.call(worker, {:render, :app, nil, %{...}, timeout}, timeout + 100)
end)
```

4. Inside the pool worker

- Each worker is a port that communicates to a Node.js process that can render React components on the server
- They listen for GenServer.call messages from Elixir like:

```elixir
{:render, :app, nil, %{...}, timeout}
```

- That message is forwarded into Node.js (react_servers/server.js) that calls the function:

```javascript
reaxt_server_render(props, renderCallback);
```

This comes from the JS code we defined in our app.js file:

```javascript
export default {
  ...
  reaxt_server_render(params, render) {
    ...
    render(<Child {...browserState} />);
  },
  ...
}
```

- So our Nodejs server calls reaxt_server_render function:
  - params is the map passed from Elixir: %{path, query, cookies}
  - render(component, status?) is a function that takes a React element and sends back:
    - the rendered HTML and props getting passed to that component
    - the status code (optional)

This is what performs server-side rendering (SSR).

5. Back to Elixir

The Node.js worker replies with:

```elixir
{:ok, %{
  html: "<div>Rendered HTML</div>",
  js_render: "function that rehydrates the app on client",
  param: status
}}
```

Reaxt.render! unwraps the result embed it in the layout.html.eex

```html
<div id="content"><%= render.html %></div>

<script id="client_script" src="/public/<%= WebPack.file_of(:main) %>"></script>

<script>
  <%= render.js_render %>.then(function(render) { return render("content") })
</script>
```

6. The client takes over

After the HTML is rendered:

- The browser loads the <script> from /public/...js
- The `render.js_render` function (injected by Reaxt) rehydrates the React app on the client side by calling `window.reaxt_render` that calls `reaxt_client_render` defined in our `app.js` file and pass to it the props (browserProps) in line 147 and a render function from `ReactDom`

Now your app is live, interactive, and uses the same props as the server.

## Questions

✅ What is Reaxt?
Reaxt is an Elixir library that integrates React with Elixir/Phoenix, enabling server-side rendering (SSR) of React components using a Node.js pool.

✅ Why do we use server-side rendering (SSR)?

- Faster first load (especially on slow connections)
- Better SEO (HTML is sent, not just JS)
- Improved accessibility and sharing (content is visible without JS)

✅ What does EEx stand for, and what are its use cases?
EEx = Embedded Elixir — it's Elixir’s templating engine that lets you embed Elixir code inside .html.eex files, mainly used to generate dynamic HTML views.
