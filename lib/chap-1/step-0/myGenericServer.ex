defmodule MyGenericServer do

  # server
  def loop({callback_module, server_state}) do

    receive do
      {:cast, request} ->
        result = callback_module.handle_cast(request, server_state)
        loop({callback_module, result})

      {:call, request, requestor_pid} ->
        {result, result} = callback_module.handle_call(request, server_state)
        send(requestor_pid, {:result, result})
        loop({callback_module, server_state})
    end

  end

  # Client
  def cast(process_pid, request) do
    send(process_pid, {:cast, request})

    :ok
  end

  def call(process_pid, request) do
    send(process_pid, {:call, request, self()})

    receive do
      {:result, result} -> result
    end
  end

  def start_link(callback_module, server_initial_state) do
    pid = spawn_link(fn -> MyGenericServer.loop({callback_module, server_initial_state}) end)
    {:ok, pid}
  end
end
