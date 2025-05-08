defmodule CowboySupervisor do
  use Supervisor
  require Logger

  def start_link(args) do
    {:ok, _} = Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_init_args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Plugs.Router, options: [port: 4001]}
    ]

    Logger.info("Server starting on port 4001 ...")

    Supervisor.init(children, strategy: :one_for_one)
  end
end
