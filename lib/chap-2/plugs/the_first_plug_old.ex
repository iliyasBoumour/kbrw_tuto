defmodule Plugs.TheFirstPlugOld do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opt) do
    case {conn.method, conn.request_path} do
      {"GET", "/me"} -> send_resp(conn, 200, "I am The First, The One, Le Geant Plug Vert, Le Grand Plug, Le Plug Cosmique.")
      {"GET", "/"} ->  send_resp(conn, 200, "Welcome to the new world of Plugs!")
      _ -> send_resp(conn, 404, "Go away, you are not welcome here.")
    end
  end
end
