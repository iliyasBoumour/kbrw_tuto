defmodule ServSupervisor do
  use Supervisor

  def start_link(arg \\ :ok) do
    {:ok, _} = Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_init_args) do
    children = [Database]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
