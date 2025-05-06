defmodule OrderPaymentProcess do
  use GenServer
  require Logger

  @timeout :timer.minutes(5)

  # Client

  def child_spec(order) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [order]},
      restart: :temporary
    }
  end

  def start_link(order) do
    GenServer.start_link(__MODULE__, order, name: String.to_atom(order["id"]))
  end

  # Server
  def init(order) do
    {:ok, order, @timeout}
  end

  def handle_call(message, _from, order) do
    try do
      {:next_state, updated_order} = ExFSM.Machine.event(order, {message, []})

      Riak.insert_into_bucket(order["id"], updated_order)

      {:reply, updated_order, updated_order, @timeout}
    rescue
      e ->
        Logger.error(e)
        {:reply, :action_unavailable, order, @timeout}
    end
  end

  def handle_info(:timeout, order) do
    OrderPaymentManager.delete_process_for_order(order)
    {:stop, :inactive, order}
  end
end
