defmodule OrderPaymentProcessesTable do
  use GenServer

  ## Client
  def table_name(), do: :order_payment_processes_table

  def start_link(args \\ :ok) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def read(key) do
    GenServer.call(__MODULE__, {:read, key})
  end

  def create({key, value}) do
    GenServer.cast(__MODULE__, {:create, {key, value}})
  end

  def delete(key) do
    GenServer.cast(__MODULE__, {:delete, key})
  end

  ## Server
  @impl true
  def init(_args) do
    table = table_name() |> :ets.new([:set, :public, :named_table])

    {:ok, table}
  end

  # Read
  @impl true
  def handle_call({:read, key}, _from, state) do
    entry =
      case table_name() |> :ets.lookup(key) do
        [] -> nil
        [{_, entry}] -> entry
      end

    {:reply, entry, state}
  end

  # Create
  @impl true
  def handle_cast({:create, payload}, state) do
    table_name() |> :ets.insert(payload)

    {:noreply, state}
  end

  # Delete
  @impl true
  def handle_cast({:delete, key}, state) do
    table_name() |> :ets.delete(key)

    {:noreply, state}
  end
end
