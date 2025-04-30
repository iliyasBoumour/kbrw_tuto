defmodule Plugs.Router do
  use Plug.Router

  plug(:match)
  plug(Plug.Static, from: "priv/static", at: "/static")

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  # Crud routes
  post("/api/orders", do: create_order(conn))

  get("/api/orders/:id", do: get_order(conn, id))

  get("/api/orders", do: get_orders(conn))

  put("/api/orders/:id", do: update_order(conn, id))

  delete("/api/orders/:id", do: delete_order(conn, id))

  get(_, do: send_file(conn, 200, "priv/static/index.html"))

  match(_, do: send_resp(conn, 404, "Page not found"))

  # service calls
  defp create_order(conn) do
    order = conn.body_params

    case order_valid?(order) do
      true ->
        Riak.insert_into_bucket(order["id"], order)
        send_resp(conn, 201, to_json(order))

      false ->
        send_resp(conn, 400, "Bad params")
    end
  end

  defp get_order(conn, order_id) do
    order = Riak.get_entry(order_id)

    case order do
      nil -> send_resp(conn, 404, "Order not found")
      order -> send_resp(conn, 200, to_json(order))
    end
  end

  defp get_orders(conn) do
    params = adapt_search_params(conn.query_params)

    orders =
      Map.fetch!(Riak.bucket_info(), :index_name)
      |> Riak.search(params[:q], params[:page], params[:rows])
      |> to_json()

    send_resp(conn, 200, orders)
  end

  defp update_order(conn, order_id) do
    order = Riak.get_entry(order_id)
    new_order = conn.body_params

    case {order, order_valid?(new_order)} do
      {nil, _} ->
        send_resp(conn, 404, "Order not found")

      {_, false} ->
        send_resp(conn, 400, "Bad params")

      {_, true} ->
        Riak.insert_into_bucket(order_id, new_order)
        send_resp(conn, 200, to_json(order))
    end
  end

  defp delete_order(conn, order_id) do
    order = Database.read(order_id)

    :timer.sleep(2000)

    case order do
      nil ->
        send_resp(conn, 404, "Order not found")

      _ ->
        Database.delete(order_id)
        send_resp(conn, 204, "")
    end
  end

  defp adapt_search_params(query_params) do
    default_params = [page: 0, rows: 30, q: ""]

    query_params
    |> Enum.reduce(default_params, fn pair, acc ->
      case pair do
        {"page", page} ->
          {parsed_page, _} = Integer.parse(page)
          Keyword.put(acc, :page, parsed_page)

        {"rows", rows} ->
          {parsed_row, _} = Integer.parse(rows)
          Keyword.put(acc, :rows, parsed_row)

        {key, value} ->
          Keyword.put(acc, :q, acc[:q] <> "#{key}:#{Riak.escape(value)}&")
      end
    end)
  end

  defp order_valid?(order) do
    ["id", "value"]
    |> Enum.all?(fn attribute -> Map.has_key?(order, attribute) end)
  end

  defp to_json(map), do: Poison.encode!(map)
end
