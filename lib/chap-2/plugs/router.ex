defmodule Plugs.Router do
  use Plug.Router

  plug :match
  plug Plug.Static, from: "priv/static", at: "/static"
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  plug :dispatch

  # Crud routes
  post "/orders", do: create_order(conn)

  get "/orders/:id", do: get_order(conn, id)

  put "/orders/:id", do: update_order(conn, id)

  delete "/orders/:id", do: delete_order(conn, id)

  get "/search", do: search_order(conn)

  get _, do: send_file(conn, 200, "priv/static/index.html")

  match _, do: send_resp(conn, 404, "Page not found")

  # service calls
  defp create_order(conn) do
    order = conn.body_params

    case order_valid?(order) do
      true ->
        Database.create({order["id"], order})
        send_resp(conn, 201, to_json(order))

      false -> send_resp(conn, 400, "Bad params")
    end
  end

  defp delete_order(conn, order_id) do
    order = Database.read(order_id)

    case order do
      nil ->  send_resp(conn, 404, "Order not found")
      _ ->
        Database.delete(order_id)
        send_resp(conn, 204, "")
    end
  end

  defp get_order(conn, order_id) do
    order = Database.read(order_id)

    case order do
      nil ->  send_resp(conn, 404, "Order not found")
      order -> send_resp(conn, 200, to_json(order))
    end
  end

  defp update_order(conn, order_id) do
    order = Database.read(order_id)
    new_order = conn.body_params

    case {order, order_valid?(new_order)} do
      {nil, _} ->  send_resp(conn, 404, "Order not found")

      {_, false} ->  send_resp(conn, 400, "Bad params")

      {_, true} ->
        Database.update({order_id, new_order})
        send_resp(conn, 200, to_json(order))
    end
  end

  defp search_order(conn) do
    criteria = conn.query_params
      |> Enum.reduce([], fn pair, acc -> [pair | acc] end)

    {:ok, orders} = Database.table_name |> Database.search(criteria)

    send_resp(conn, 200, to_json(orders))
  end

  defp order_valid?(order) do
    ["id", "value"]
      |> Enum.all?(fn attribute -> Map.has_key?(order, attribute) end)
  end

  defp to_json(map), do: Poison.encode!(map)

end
