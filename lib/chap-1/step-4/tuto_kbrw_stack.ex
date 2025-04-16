defmodule TutoKbrwStack do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ServSupervisor
    ]

    opts = [strategy: :one_for_one, name: TutoKbrwStack.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
