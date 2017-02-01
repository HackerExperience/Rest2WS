defmodule Rest2WS.Plug do

  import Plug.Conn

  def init(args),
    do: args

  def call(conn, args) do
    process(conn, args)
  end

  defp process(conn, args) do

    # Add route_map to the connection info
    routes = Application.fetch_env!(:rest2ws, :routes)
    conn = put_private(conn, :rest2ws_routes, routes)

    # Start Rest2WS magic and wait for the result
    Rest2WS.submit(conn, self())

    receive do
      {:error, reason} ->
        # LOGME: reason
        conn
      {:ok, conn} ->
        conn
    end
  end
end
