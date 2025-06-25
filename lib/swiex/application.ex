defmodule Swiex.Application do
  use Application

  def start(_type, _args) do
    children = [
      # No children needed - MQI server is started by the client
    ]

    opts = [strategy: :one_for_one, name: Swiex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
