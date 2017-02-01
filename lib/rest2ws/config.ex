defmodule Rest2WS.Exception.InvalidRouteJSON do
  defexception message: "failed to parse route json"
end

defmodule Rest2WS.Config do

  def load(path) do
    routes_json = File.read!(path)

    case Poison.Parser.parse(routes_json) do
      {:ok, routes} ->
        Application.put_env(:rest2ws, :routes, routes)
      _ ->
        raise Rest2WS.Exception.InvalidRouteJSON
    end
  end
end
