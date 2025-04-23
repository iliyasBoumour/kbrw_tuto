# Cowboy

## Cowboy_plug

- `Cowboy`: a small, fast, and modern `HTTP server`. It handles the low-level stuff: sockets, HTTP/1 and HTTP/2, requests/responses (Like Tomcat or Node's HTTP server)
- `Plug`: an application server — it’s more like a web framework or middleware layer. It defines how to handle requests once Cowboy passes them along. (Like Spring MVC or Express.js – where you define request handling.)
- `plug_cowboy`: The bridge between Plug (logic) and Cowboy (server). Starts the server.

## Create a plug cowboy server

In order to do this we need to pass through several steps:

### Using Plug.Conn

#### Implement plug conn

In order to do this we need to implement `Plug.Conn` behaviour, end then implement it's two functions:`init` and `call`

Here’s a simple Plug that returns “Hello World!”:

```elixir
defmodule Example.HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!\n")
  end
end
```

- The `init/1` function is used to initialize our Plug’s options. It is called by a supervision tree (see bellow)
- The value returned from `init/1` will eventually be passed to `call/2` as its second argument.
- The `call/2` function is called for every new request that comes in from the web server, Cowboy. It receives a `%Plug.Conn{}` connection struct as its first argument and is expected to return a `%Plug.Conn{}` connection struct.
- The `send_resp/3` function sends response to our server

#### Configure tha application module

We need to tell our application to start up and supervise the Cowboy web server when the app starts up.

We’ll do so with the `Plug.Cowboy.child_spec/1` function that takes three args: - `:scheme` - HTTP or HTTPS as an atom (:http, :https) - `:plug` - The plug module to be used as the interface for the web server. You can specify a module name, like `MyPlug`, or a tuple of the module name and options `{MyPlug, plug_opts}`, where plug_opts gets passed to your plug modules `init/1` function. - `:options` - The server options. Should include the port number.

```elixir
defmodule Example.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Example.HelloWorldPlug, options: [port: 8080]}
    ]
    opts = [strategy: :one_for_one, name: Example.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end
end
```

### Using Plug.Router

To build a REST API, you’ll want a router to route requests for different paths and HTTP verbs to different handlers. Plug provides a router to do that.

```elixir
defmodule Example.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
```

- `use Plug.Router` : includes some macros
- `:match` and `:dispatch` : set up two of the built-in Plugs (middelwares)
  - `:match`: a middeleware that takes request path, method... and match them with all defined routes
  - `:dispatch`: do the rest of the job, whe the controller is called, it calls the right action with the conn object

## Serving static files with Plug.Static

this plug is used to serve static files and it takes two params:

- `:at`: the request path to reach for static assets.
- `:from`: the file system path to read static assets from.

```elixir
# If i sent a request to /static go and serve files from priv/app/path
plug Plug.Static, from: {:app_name, "priv/app/path"}, at: "/static"
```
