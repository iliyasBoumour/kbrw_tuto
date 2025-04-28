defmodule Riak do
  ## Utility functions
  def url, do: "https://kbrw-sb-tutoex-riak-gateway.kbrw.fr"

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

  defp request_cluster(method, path, body, content_type \\ 'application/json') do
    url = '#{Riak.url()}#{path}'
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
      200 -> response |> Map.fetch!(key)
      _ -> nil
    end
  end

  def delete_entry(key, %{bucket_name: bucket} \\ Riak.bucket_info()) do
    {204, _} = request_cluster(:delete, "/buckets/#{bucket}/keys/#{key}", nil)

    :ok
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
    # {200, %{"props" => props}} =
    #   request_cluster(:get, "/types/default/buckets/#{bucket}/props", nil)

    Riak.empty_bucket(bucket)
    request_cluster(:delete, "/types/default/buckets/#{bucket}/props", nil)

    # index = props["search_index"]
    # request_cluster(:delete, "/search/index/#{index}", nil)

    :ok
  end
end
