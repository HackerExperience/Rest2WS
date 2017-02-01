defmodule Rest2WS do

  import Plug.Conn

  def submit(conn, reply_to) do
    spawn_link(fn ->
      Rest2WS.process(conn, reply_to)
    end)
  end

  def process(conn, reply_to) do

    request = %Rest2WS.WSRequest{}
    |> fetch_route_data(conn)
    |> generate_request(conn)
    |> send_request()

    response = case request do
      {:error, error} ->
        create_response({:error, error})
      _ ->
        receive do
          {:recv, msg} ->
            create_response(msg)
          _ ->
            create_response(:error)
        end
    end

    conn = resp(conn, response.status, response.body)

    send reply_to, {:ok, conn}
  end

  defp create_response({:error, error}),
    do: %Rest2WS.Response{status: 500, body: error}

  defp create_response(:error),
    do: create_response({:error, "rest2ws internal error"})

  defp create_response(result) do

    get_status = fn(code) ->
      if code do
        code
      else
        500
      end
    end

    get_body = fn(data, status) ->
      case status do
        500 ->
          "rest2ws error: bad response format"
        _ ->
          if data do
            Poison.encode!(data)
          else
            ""
          end
      end
    end

    code = Access.get(result, "code", false)
    data = Access.get(result, "data", false)

    status = get_status.(code)
    body = get_body.(data, status)

    %Rest2WS.Response{status: code, body: body}
  end

  defp generate_request({:ok, route_info}, conn) do
    get_param_name = fn(key) ->
      Map.get(route_info["args"], key, key)
    end

    body_params = case conn.method do
      "GET" ->
        %{}
      _ ->
       {:ok, body, _} = read_body(conn)
       Poison.Parser.parse!(body)
    end

    url_params = conn.params

    params = Map.merge(url_params, body_params)

    # The REST API param might be different than the one required by the
    # websocket API. Here we iterate through the route definition and use
    # the param key defined by the user. If no key was defined, we keep using
    # the original REST param key.
    args = params
    |> Enum.reduce(%{}, fn(param, acc) ->
      {arg_key, arg_val} = param
      Map.merge(acc, %{get_param_name.(arg_key) => arg_val})
    end)

    topic = route_info["topic"]

    request_id = generate_uuid()
    |> persist_uuid(conn.owner)

    request = %Rest2WS.WSRequest{topic: topic, args: args, request_id: request_id}

    {:ok, request}

  end

  defp generate_request({:error, error}, _conn),
    do: {:error, error}

  defp fetch_route_data(request, conn) do

    {path, params} = {conn.path_info, conn.params}

    # If we have /user/u1/post/p1/comment/c1,
    # return: /user/:user_id/post/:post_id/comment/:comment_id,
    # where the corresponding keys are defined at the Phoenix.Router
    rest_path = path
    |> List.delete_at(0)  # tmp, remove "/api"
    |> Enum.reduce([], fn(param, new_path) ->
      append_value = Enum.find(params, fn({k, v}) ->
        v == param
      end)
      |> case do
        nil ->
          param
        {key, param} ->
          ":#{key}"
      end
      new_path ++ [append_value]
    end)
    |> Enum.join("/")

    rest_path = "/" <> rest_path

    with {:ok, namespace_data} <- Map.fetch(get_route_map(conn), rest_path),
         {:ok, route_data} <- Map.fetch(namespace_data, String.downcase(conn.method)) do
      {:ok, route_data}
    else
      :error ->
        {:error, "rest2ws error: path not found on route map"}
    end
  end

  defp send_request({:ok, request}) do
    SmartWebsocketClient.send(request)
    {:ok, "result"}
  end

  defp send_request({:error, error}),
    do: {:error, error}

  defp generate_uuid() do
    UUID.uuid4()
  end

  defp persist_uuid(request_id, reply_to) do
    Rest2WS.RequestManager.insert(request_id, self())
    request_id
  end

  defp get_route_map(conn),
    do: conn.private[:rest2ws_routes]

end
