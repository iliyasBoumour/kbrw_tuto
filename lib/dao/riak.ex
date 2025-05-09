defmodule Riak do
  ## Utility functions
  def url, do: "https://kbrw-sb-tutoex-riak-gateway.kbrw.fr"

  ## Crud operations
  def get_bucket_keys(%{bucket_name: bucket} \\ Riak.bucket_info()) do
    {200, response} = request_cluster(:get, "/buckets/#{bucket}/keys?keys=true", nil)

    response |> Map.fetch!("keys")
  end

  def insert_into_bucket(key, value, %{bucket_name: bucket} \\ Riak.bucket_info()) do
    {204, _} = request_cluster(:put, "/buckets/#{bucket}/keys/#{key}", value)

    :ok
  end

  def get_entry(key, %{bucket_name: bucket} \\ Riak.bucket_info()) do
    {code, response} = request_cluster(:get, "/buckets/#{bucket}/keys/#{key}", nil)

    case code do
      200 -> response
      _ -> nil
    end
  end

  def delete_entry(key, %{bucket_name: bucket} \\ Riak.bucket_info()) do
    {204, _} = request_cluster(:delete, "/buckets/#{bucket}/keys/#{key}", nil)

    :ok
  end

  def search(index, query, page \\ 0, rows \\ 30, sort \\ "creation_date_index") do
    query_param =
      case query do
        "" -> "*:*"
        _ -> query
      end

    {_code, response} =
      request_cluster(
        :get,
        "/search/query/#{index}/?wt=json&q=#{query_param}&start=#{page * rows}&rows=#{rows}&sort=#{
          sort
        } desc",
        nil
      )

    case response do
      %{"error" => %{"msg" => msg}} ->
        msg

      %{"response" => %{"docs" => docs, "numFound" => numFound}} ->
        %{total_count: numFound, page: page, rows: rows, orders: entries_from_indexes(docs)}
    end
  end

  defp entries_from_indexes(indexed_docs) do
    indexed_docs
    |> Task.async_stream(
      fn doc ->
        doc_id = doc["id"] |> hd
        Riak.get_entry(doc_id)
      end,
      [{:max_concurrency, 10}]
    )
    |> Enum.map(fn {:ok, order} -> order end)
  end

  ## schema & index
  def upload_schema(%{schema_name: schema_name, schema_path: schema_path} \\ Riak.bucket_info()) do
    file_content = File.read!(schema_path)

    {204, _} =
      request_cluster(:put, "/search/schema/#{schema_name}", file_content, 'application/xml')

    :ok
  end

  def create_index(%{schema_name: schema_name, index_name: index_name} \\ Riak.bucket_info()) do
    {204, _} = request_cluster(:put, "/search/index/#{index_name}", %{schema: schema_name})

    :ok
  end

  def list_indexes() do
    {200, list} = request_cluster(:get, "/search/index", nil)

    list
  end

  def assign_index_to_bucket(%{bucket_name: bucket, index_name: index_name} \\ Riak.bucket_info()) do
    {204, _} =
      request_cluster(:put, "/buckets/#{bucket}/props", %{props: %{search_index: index_name}})

    :ok
  end

  ## bucket
  def get_buckets do
    {200, response} = request_cluster(:get, "/buckets?buckets=true", nil)

    response |> Map.fetch!("buckets")
  end

  def empty_bucket(bucket_name \\ nil) do
    bucket =
      case bucket_name do
        nil -> Riak.bucket_info()[:bucket_name]
        name -> name
      end

    Riak.get_bucket_keys(%{bucket_name: bucket})
    |> Enum.each(fn key -> Riak.delete_entry(key) end)

    :ok
  end

  def delete_bucket(%{bucket_name: bucket} \\ Riak.bucket_info()) do
    {200, %{"props" => props}} =
      request_cluster(:get, "/types/default/buckets/#{bucket}/props", nil)

    Riak.empty_bucket(bucket)
    {204, _} = request_cluster(:delete, "/types/default/buckets/#{bucket}/props", nil)

    :timer.sleep(2000)

    index = props["search_index"]
    request_cluster(:delete, "/search/index/#{index}", nil)

    :ok
  end

  # Helpers

  def bucket_info,
    do: %{
      schema_name: "ILIYAS_orders_schema",
      schema_path: "lib/chap-6/schema-riak.xml",
      index_name: "ILIYAS_orders_index",
      bucket_name: "ILIYAS_orders"
    }

  defp auth_header do
    username = "sophomore"
    password = "jlessthan3tutoex"
    auth = :base64.encode_to_string("#{username}:#{password}")
    [{'authorization', 'Basic #{auth}'}]
  end

  defp get_response_data(response) do
    {:ok, {{_http_v, code, _http_message}, _headers, body}} = response

    {_, decoded_body} = Poison.decode(body)

    {code, decoded_body}
  end

  def escape(path) do
    forbidden_chars = [
      "+",
      "-",
      "&&",
      "||",
      "!",
      "(",
      ")",
      "{",
      "}",
      "[",
      "]",
      "^",
      "\"",
      "~",
      "*",
      "?",
      ":",
      "/"
    ]

    path
    |> String.graphemes()
    |> Enum.map(fn char ->
      case Enum.member?(forbidden_chars, char) do
        true ->
          "\\#{char}"

        _ ->
          char
      end
    end)
    |> Enum.join()
  end

  defp request_cluster(method, path, body, content_type \\ 'application/json') do
    encoded_path = URI.encode(path)
    url = '#{Riak.url()}#{encoded_path}'
    headers = auth_header()

    encoded_body =
      case content_type do
        'application/json' -> Poison.encode!(body)
        _ -> body
      end

    request =
      case body do
        nil -> {url, headers}
        _ -> {url, headers, content_type, encoded_body}
      end

    :httpc.request(method, request, [], []) |> get_response_data()
  end
end
