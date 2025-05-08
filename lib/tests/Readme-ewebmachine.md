# Ewebmachine.Builder.Handlers

## code walkthrough

### **using\_** (added to module)

```elixir
defmacro __using__(_opts) do
  quote location: :keep do
    use Plug.Builder
    import Ewebmachine.Builder.Handlers
    @before_compile Ewebmachine.Builder.Handlers
    @resource_handlers %{}
    ping do: :pong
  end
end
```

When we write `use Ewebmachine.Builder.Handlers`:

- Inherits Plug.Builder so we can use plug commands
- Imports this module’s macros (like defh, resource_exists)
- Registers a `@before_compile` hook to inject `add_handlers`
- Initializes an empty map of `@resource_handlers`
- Defines a default `ping` handler (returns `:pong`)

### `before compile` (added to module)

```elixir
defmacro __before_compile__(_env) do
  quote do
    defp add_handlers(conn, opts) do
      conn = case Access.fetch(opts, :init) do
        {:ok, init} when not (init in [false, nil]) ->
          put_private(conn, :machine_init, init)
        _ -> conn
      end
      Plug.Conn.put_private(conn, :resource_handlers,
        Enum.into(@resource_handlers, conn.private[:resource_handlers] || %{}))
    end
  end
end
```

What this does:

- This macro injects a function `add_handlers` into the module.
- When plug `:add_handlers` is used:
  - It sets `coon.private[:machine_init]` in the connection (if provided in opts[:init]) it is our `state` variable.
  - It stores the defined handlers (from `@resource_handlers`) into `conn.private[:resource_handlers]`.

#### Usage

```elixir
  use Ewebmachine.Builder.Handlers
  plug :add_handlers, init: %{}
```

### `@resource_fun_names` (helper)

```elixir
@resource_fun_names [
  :resource_exists, :service_available, :is_authorized, ...
]
```

- These are the standard handler names that `Ewebmachine` can call to make decisions during request handling.
- We'll use these when defining handlers with `resource_exists do ... end`, etc.

### `defh` (usable macro)

```elixir
defmacro defh(signature, do_block) do
  ...
end
```

This is a macro that uses the `handler_quote` helper to define and register the function:

- It define any custom handler (like to_json, from_json)
- Add it to the map `@resource_handlers`
- Wraps the result so `Ewebmachine` can understand it ({:value, conn, state})
- We can write guards and pattern matching

```elixir
defh to_json, do: "hello"
# defines: def to_json(conn, state), do: {"hello", conn, state}
```

### Default handlers (added to module)

```elixir
for resource_fun_name <- @resource_fun_names do
  Module.eval_quoted(Ewebmachine.Builder.Handlers, quote do
    @doc "see `Ewebmachine.Handlers.#{unquote(resource_fun_name)}/2`"
    defmacro unquote(resource_fun_name)(do_block) do
      name = unquote(resource_fun_name)
      handler_quote(name,do_block[:do])
    end
  end)
end
```

Each macro defines the default function for each handler `@resource_handlers` from `Ewebmachine.Builder.Handlers` file

We can overwrite them if we want

### `pass` (usable macro)

Helper for adding state to response, instead of doing this manually:

```elixir
{:ok, conn, Map.put(state, :user, user)}
```

We can just write:

```elixir
pass :ok, user: user
```

# Ewebmachine.Builder.Resources

# Annex

## Plug.conn object

```elixir
%{
  adapter: {Plug.Cowboy.Conn},
  assigns: %{},
  body_params: %{},
  cookies: %Plug.Conn.Unfetched{aspect: :cookies},
  halted: false,
  host: "0.0.0.0",
  method: "GET",
  owner: #PID<0.702.0>,
  params: %{"page" => "0"},
  path_info: ["api", "orders"],
  path_params: %{},
  port: 4001,
  private: %{
    plug_route: {"/*_path/api/orders",
     #Function<10.9742982/2 in Plugs.Router.do_match/4>}
  },
  query_params: %{"page" => "0"},
  query_string: "page=0",
  remote_ip: {127, 0, 0, 1},
  req_cookies: %Plug.Conn.Unfetched{aspect: :cookies},
  req_headers: [
    {"accept", "application/json,*/*;0.8"},
    {"connection", "keep-alive"},
    {"content-length", "0"},
    {"content-type", "application/json"},
    {"host", "0.0.0.0:4001"},
    {"user-agent",
     "Mozilla/5.0 (Darwin arm64) node.js/16.10.0 v8/9.3.345.19-node.14"}
  ],
  request_path: "/api/orders",
  resp_body: nil,
  resp_cookies: %{},
  resp_headers: [{"cache-control", "max-age=0, private, must-revalidate"}],
  scheme: :http,
  script_name: [],
  secret_key_base: nil,
  state: :unset,
  status: nil
}
```

# Example

```elixir
defmodule MyJSONApi do
  use Ewebmachine.Builder.Handlers
  plug :cors
  plug :add_handlers, init: %{}

  content_types_provided do: ["application/json": :to_json]
  defh to_json, do: Poison.encode!(state[:json_obj])

  defp cors(conn,_), do:
    put_resp_header(conn,"Access-Control-Allow-Origin","*")
end

defmodule ErrorRoutes do
  use Ewebmachine.Builder.Resources ; resources_plugs

  resource "/error/:status" do %{s: elem(Integer.parse(status),0)} after
    content_types_provided do: ['text/html': :to_html, 'application/json': :to_json]

    defh to_html, do: "<h1> Error ! : '#{Ewebmachine.Core.Utils.http_label(state.s)}'</h1>"
    defh to_json, do: ~s/{"error": #{state.s}, "label": "#{Ewebmachine.Core.Utils.http_label(state.s)}"}/

    finish_request do: {:halt,state.s}
  end
end

defmodule FullApi do
  use Ewebmachine.Builder.Resources
  if Mix.env == :dev, do: plug Ewebmachine.Plug.Debug
  resources_plugs error_forwarding: "/error/:status", nomatch_404: true
  plug ErrorRoutes

  resource "/hello/:name" do %{name: name} after
    content_types_provided do: ['application/xml': :to_xml]
    defh to_xml, do: "<Person><name>#{state.name}</name>"
  end

  resource "/hello/json/:name" do %{name: name} after
    plug MyJSONApi #this is also a plug pipeline
    allowed_methods do: ["GET","DELETE"]
    resource_exists do: pass((user=DB.get(state.name)) !== nil, json_obj: user)
    delete_resource do: DB.delete(state.name)
  end

  resource "/static/*path" do %{path: Enum.join(path,"/")} after
    resource_exists do:
      File.regular?(path state.path)
    content_types_provided do:
      [{state.path|>Plug.MIME.path|>default_plain,:to_content}]
    defh to_content, do:
      File.stream!(path(state.path),[],300_000_000)
    defp path(relative), do: "#{:code.priv_dir :ewebmachine_example}/web/#{relative}"
    defp default_plain("application/octet-stream"), do: "text/plain"
    defp default_plain(type), do: type
  end
end
```
