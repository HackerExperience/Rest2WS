defmodule Rest2WS.RequestManager do
  use GenServer

  @rest2ws_bucket Application.get_env(:rest2ws, :ets_table, :rest2ws_request)

  # TODO: Use Immortal so ETS data can persist across crashes.
  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do

    Rest2WS.Config.load(Application.fetch_env!(:rest2ws, :route_file))

    ws_config = Application.fetch_env!(:rest2ws, :ws_config)
    swc_config = %SmartWebsocketClient.Connection{
      host: ws_config[:host],
      port: ws_config[:port] || 80,
      path: ws_config[:path] || "/"
    }

    SmartWebsocketClient.connect(swc_config, Rest2WS.Listener)

    :ets.new(@rest2ws_bucket, [:named_table])
    {:ok, %{}}
  end

  def insert(key, value) do
    GenServer.call(:request_manager, {:insert, key, value})
  end

  def fetch(key) do
    GenServer.call(:request_manager, {:fetch, key})
  end

  def handle_call({:insert, key, value}, _from, _state) do
    :ets.insert(@rest2ws_bucket, {key, value})
    {:reply, :ok, _state}
  end

  def handle_call({:fetch, key}, _from, _state) do
    result = :ets.lookup(@rest2ws_bucket, key)
    |> List.first()
    |> case do
         {_key, value} ->
           value
         _ ->
           nil
       end
    {:reply, result, _state}
  end
end
