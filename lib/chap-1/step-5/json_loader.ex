defmodule JsonLoader do
  defp json_file, do: "lib/chap-1/resources/orders_chunk0.json"

  def load_to_ets_database(database, json_file) do
    File.read!(json_file)
    |> Poison.decode!()
    |> Enum.each(fn order -> :ets.insert(database, {order["id"], order}) end)
  end

  def load_to_ets do
    JsonLoader.load_to_ets_database(:database_table, json_file())
  end

  def load_to_riak() do
    File.read!(json_file())
    |> Poison.decode!()
    |> Task.async_stream(
      fn order -> Riak.insert_into_bucket(order["id"], order) end,
      [{:max_concurrency, 10}]
    )
    |> Enum.to_list()
  end
end
