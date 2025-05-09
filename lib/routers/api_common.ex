defmodule ApiCommon do
  use Ewebmachine.Builder.Handlers
  plug(:cors)

  plug(:add_handlers)

  content_types_provided(do: ["application/json": :to_json])

  defh(to_json, do: Poison.encode!(state))

  content_types_accepted(do: ["application/json": :from_json])

  defp cors(conn, _), do: put_resp_header(conn, "Access-Control-Allow-Origin", "*")
end
