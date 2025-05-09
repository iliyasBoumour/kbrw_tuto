defmodule Plugs.Router do
  use Ewebmachine.Builder.Resources
  require EEx

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  if Mix.env() == :dev do
    use Plug.Debugger
    plug(Ewebmachine.Plug.Debug)
    plug(WebPack.Plug.Static, at: "/public", from: :formation)
  else
    plug(Plug.Static, at: "/public", from: :formation)
  end

  resources_plugs(error_forwarding: "/error/:status", nomatch_404: true)
  plug(ErrorRouter)

  # Crud routes
  resource "/api/orders" do
    %{}
  after
    plug(ApiCommon)
    allowed_methods(do: ["POST", "GET"])

    # Handle GET
    resource_exists(do: pass(true, OrdersService.get_all(conn.params)))

    # Handle POST
    post_is_create(do: true)
    create_path(do: state.path)

    defh from_json(conn, state) do
      order = conn.body_params
      pass(OrdersService.create(order), path: conn.request_path <> order["id"])
    end
  end

  resource "/api/orders/:id" do
    %{id: id}
  after
    plug(ApiCommon)
    allowed_methods(do: ["DELETE", "GET", "PUT"])

    # GET
    resource_exists do
      case OrdersService.get_by_id(state.id) do
        nil -> pass(false, status: 404)
        order -> pass(true, order)
      end
    end

    # DELETE
    delete_resource(do: OrdersService.delete(state.id))

    # PUT
    create_path(do: state.path)

    defh from_json(conn, state) do
      order = conn.body_params
      pass(OrdersService.update(state.id, order), path: conn.request_path <> order["id"])
    end
  end

  resource "/api/orders/:id/pay" do
    %{id: id}
  after
    plug(ApiCommon)

    allowed_methods(do: ["POST"])

    post_is_create(do: true)
    create_path(do: state.path)

    defh from_json do
      pass(OrdersService.pay(state.id), path: "/api/orders/#{state.id}")
    end
  end

  resource "/*path" do
    %{}
  after
    EEx.function_from_file(:defp, :layout, "web/layout.html.eex", [:render])

    content_types_provided(do: ["text/html": :to_html])

    defh(to_html, do: state.html)

    resource_exists do
      render =
        Reaxt.render!(
          :app,
          %{path: conn.request_path, cookies: conn.cookies, query: conn.params},
          30_000
        )

      pass(true, html: layout(render))
    end
  end
end
