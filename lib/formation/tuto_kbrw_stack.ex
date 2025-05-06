defmodule Formation.TutoKbrwStack do
  use Application

  @impl true
  def start(_type, _args) do
    Application.put_env(
      :reaxt,
      :global_config,
      Map.merge(
        Application.get_env(:reaxt, :global_config),
        %{localhost: "http://0.0.0.0:4001"}
      )
    )

    Reaxt.reload()

    children = [
      OrderPaymentProcessesTable,
      {DynamicSupervisor, name: Formation.DynamicSupervisor, strategy: :one_for_one},
      ServSupervisor,
      CowboySupervisor
    ]

    opts = [strategy: :one_for_one, name: Formation.TutoKbrwStack.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
