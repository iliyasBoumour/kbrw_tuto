defmodule Macros.Err do
  defmacro __using__(_) do
    quote do
      use Plug.Router
      import Macros.Err

      plug :match
      plug :dispatch
    end
  end

  defmacro my_error(conn, code: status_code, content: error_message) do
    quote do
      get _ do
        send_resp(unquote(conn), unquote(status_code), unquote(error_message))
      end
    end
  end

  defmacro my_get(path, {code, message}) do
    quote do
      get unquote(path) do
        send_resp(var!(conn), unquote(code), unquote(message))
      end
    end
  end

end
