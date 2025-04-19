defmodule Database do
  use GenServer

  ## Client

  def table_name(), do: :database_table

  def start_link(args \\ :ok) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Search

  defp order_matching_criteria?(order, criteria) do
    Enum.any?(criteria, fn {key, value} -> order[key] === value end)
  end

  def search(database, criteria) do
    orders = database
      |> :ets.tab2list
      |> Enum.filter(fn {_, order} -> order_matching_criteria?(order, criteria) end)
      |> Enum.map(fn {_, order} -> order end)

      {:ok, orders}
  end

  # CRUD

  def read(key) do
    GenServer.call(__MODULE__, {:read, key})
  end

  def create({key, value}) do
    GenServer.cast(__MODULE__, {:create, {key, value}})
  end

  def update({key, value}) do
    create({key, value})
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

  @impl true
  def handle_call({:read, key}, _from, state) do
    entry = case table_name() |> :ets.lookup(key) do
      [x] -> x
      [] -> nil
    end

    {:reply, entry, state}
  end

  @impl true
  def handle_cast({:create, payload}, state) do
    table_name() |> :ets.insert(payload)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:delete, key}, state) do
    table_name() |> :ets.delete(key)

    {:noreply, state}
  end
end
