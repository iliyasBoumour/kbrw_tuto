defmodule HelloPort do
  use GenServer

  ## Client

  def start_link() do
    GenServer.start_link(__MODULE__, {"node hello.js", 0, cd: "./web"}, name: __MODULE__)
  end

  def call(message) do
    GenServer.call(__MODULE__, message)
  end

  def cast(message) do
    GenServer.cast(__MODULE__, message)
  end

  ## Server

  def init({cmd, port_initial_state, opts}) do
    port = Port.open({:spawn, '#{cmd}'}, [:binary, :exit_status, packet: 4] ++ opts)
    send(port, {self(), {:command, :erlang.term_to_binary(port_initial_state)}})

    {:ok, port}
  end

  def handle_call(message, _reply_to, port) do
    send(port, {self(), {:command, :erlang.term_to_binary(message)}})

    res =
      receive do
        {^port, {:data, b}} -> :erlang.binary_to_term(b)
      end

    {:reply, res, port}
  end

  def handle_cast({:kbrw, number}, port) do
    send(port, {self(), {:command, :erlang.term_to_binary({:kbrw, number})}})

    {:noreply, port}
  end
end
