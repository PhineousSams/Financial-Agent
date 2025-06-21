defmodule FinancialAgentWeb.Plugs.BasicAuth do
  @behaviour Plug
  import Plug.Conn

  alias FinancialAgent.Settings
  alias FinancialAgent.Workers.Util.AuthDecoder

  def init(default), do: default

  def call(conn, _default) do

    try do
      case AuthDecoder.decode_basic_auth(conn) do
        {:ok, auth} -> assign(conn, :auth, auth)
        _any->
          send_response(conn, 401, "Authentication error, missing required params!!")
      end

    rescue
      _error->
        send_response(conn, 401, "Authentication error!!!")
    end
  end


  defp send_response(conn, code, msg) do
    msg = %{code: code, description: msg}|> Poison.encode!()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(code, msg)
    |> halt()
  end

end
