defmodule JsonLoader do
  def load_to_database(database, json_file) do
    File.read!(json_file)
      |> Poison.decode!
      |> Enum.each(fn order -> :ets.insert(database,{order["id"], order}) end)
  end

  def load do
    JsonLoader.load_to_database :database_table, "lib/chap-1/resources/orders_chunk0.json"
  end
end
