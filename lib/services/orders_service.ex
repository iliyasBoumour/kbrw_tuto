defmodule OrdersService do
  def get_all(query_params) do
    params = adapt_search_params(query_params)

    Map.fetch!(Riak.bucket_info(), :index_name)
    |> Riak.search(params[:q], params[:page], params[:rows])
  end

  def get_by_id(id) do
    Riak.get_entry(id)
  end

  def create(order) do
    case order_valid?(order) do
      true ->
        Riak.insert_into_bucket(order["id"], order)
        true

      false ->
        false
    end
  end

  def delete(id) do
    :timer.sleep(2000)

    case Riak.get_entry(id) do
      nil ->
        false

      _ ->
        Riak.delete_entry(id)
        true
    end
  end

  def update(id, order) do
    case {Riak.get_entry(id), order_valid?(order)} do
      {nil, _} ->
        false

      {_, false} ->
        false

      {_, true} ->
        Riak.insert_into_bucket(id, order)
        true
    end
  end

  def pay(order_id) do
    case Riak.get_entry(order_id) do
      nil ->
        false

      order ->
        case OrderPaymentManager.pay(order) do
          :action_unavailable -> false
          _ -> true
        end
    end
  end

  # Utils

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
    ["id"]
    |> Enum.all?(fn attribute -> Map.has_key?(order, attribute) end)
  end
end
