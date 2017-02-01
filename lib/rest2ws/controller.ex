defmodule Rest2WS.Controller do
  defmacro __using__(opts) do
    quote location: :keep do

      use unquote(opts[:namespace]).Web, :controller
      plug Rest2WS.Plug

      @doc false
      def show(conn, args) do
        send_resp(conn)
      end

      @doc false
      def index(conn, args) do
        send_resp(conn)
      end

      @doc false
      def create(conn, args) do
        send_resp(conn)
      end

      defoverridable [show: 2, index: 2, create: 2]

    end
  end
end
