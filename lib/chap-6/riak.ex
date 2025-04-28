defmodule Riak do

  ## Utility functions

  def url, do: "https://kbrw-sb-tutoex-riak-gateway.kbrw.fr"

  def bucket, do: "ILIYAS_orders"

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

  defp request_cluster(method, path, body) do
    url = '#{Riak.url}#{path}'
    headers =  auth_header()

    request = case body do
      nil -> {url, headers}
      _ -> {url, headers, 'application/json', Poison.encode!(body)}
    end

    :httpc.request(method, request, [], []) |> get_response_data()
  end

  ## Crud operations

  def get_buckets do
    {200, response} = request_cluster(:get, "/buckets?buckets=true", nil)

    response |> Map.fetch!("buckets")
  end

  def get_bucket_keys(bucket \\ Riak.bucket) do
    {200, response} = request_cluster(:get, "/buckets/#{bucket}/keys?keys=true", nil)

    response |> Map.fetch!("keys")
  end

  def insert_into_bucket(key, value, bucket \\ Riak.bucket) do
    {204, _} = request_cluster(:put, "/buckets/#{bucket}/keys/#{key}", value)

    :ok
  end

  def get_entry(key, bucket \\ Riak.bucket) do
    {code, response} = request_cluster(:get, "/buckets/#{bucket}/keys/#{key}", nil)

    case code do
      200 -> response |> Map.fetch!(key)
      _ -> nil
    end
  end

  def delete_entry(key, bucket \\ Riak.bucket) do
    {204, _} = request_cluster(:delete, "/buckets/#{bucket}/keys/#{key}", nil)

    :ok
  end
end
