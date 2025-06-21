defmodule FinincialAgentWeb.AuthController do
  use FinincialAgentWeb, :controller

  alias FinincialAgent.Workers.Helpers.ApiAuth

  def sign_in(conn, _params) do
    params = conn.assigns.auth
    ip_address = ip_address(conn)
    res = ApiAuth.authenticate(params, ip_address)
    json(conn, res)
  end

  def sign_out(conn, %{"access_token" => token} = params) do
    res = ApiAuth.invalidate(token)
    json(conn, res)
  end

  def refresh(conn, %{"access_token" => token} = params) do
    res = ApiAuth.refresh_token(token)
    json(conn, res)
  end


  def ip_address(conn, _live \\ false) do
    forwarded_for = List.first(Plug.Conn.get_req_header(conn, "x-forwarded-for"))

    if forwarded_for do
      String.split(forwarded_for, ",")
      |> Enum.map(&String.trim/1)
      |> List.first()
    else
      to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end
end
