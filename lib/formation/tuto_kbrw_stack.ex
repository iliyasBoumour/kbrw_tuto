defmodule Formation.TutoKbrwStack do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ServSupervisor,
      CowboySupervisor
    ]

    opts = [strategy: :one_for_one, name: Formation.TutoKbrwStack.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
