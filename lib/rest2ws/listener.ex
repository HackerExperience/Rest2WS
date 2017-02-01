defmodule Rest2WS.Listener do

  use SmartWebsocketClient.Listener

  def on_receive(msg) do

    msg = Poison.Parser.parse!(msg)
    request_id = get_request_id(msg)
    reply_to = Rest2WS.RequestManager.fetch(request_id)

    send reply_to, {:recv, msg}

  end

  defp get_request_id(msg) do
    msg
    |> Access.fetch("request_id")
    |> Kernel.elem(1)
  end

end
