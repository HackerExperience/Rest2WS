defmodule Rest2WS.App do
  use Application
  import Supervisor.Spec

  @doc false
  def start(_type, _second) do

    children = [
      worker(Rest2WS.RequestManager, [[], [name: :request_manager]])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
