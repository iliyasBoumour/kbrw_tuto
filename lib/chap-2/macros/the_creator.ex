defmodule Macros.TheCreator do

  defmacro __using__(_) do
    quote do
      import Plug.Conn
      import Macros.TheCreator

      @before_compile Macros.TheCreator

      @function_names %{}
      @on_error {404, "not found"}
    end
  end

  defmacro my_get(path, do: expr) do
    function_name = String.to_atom("get_"<>path)

    quote do
      @function_names Map.put(@function_names, unquote(path), unquote(function_name))
      def unquote(function_name)(), do: unquote(expr)
    end
  end

  defmacro my_error(code: status_code, content: error_message) do
    quote do
      @on_error {unquote(status_code), unquote(error_message)}
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def init(opts), do: opts

      def call(conn, _) do
        function_name = @function_names[conn.request_path]
        {error_code, error_message} = @on_error

        case function_name do
          nil -> send_resp(conn, error_code, error_message)

          _ ->
            {status, message} = apply(__MODULE__, function_name, [])
            send_resp(conn, status, message)
        end
      end
    end
  end
end
