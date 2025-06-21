defmodule FinincialTool.Workers.Util.AuthDecoder  do

  def decode_basic_auth(conn) do
    case get_basic_auth_header(conn) do
      {:ok, encoded_token} ->
        case decode_basic_auth_token(encoded_token) do
          {:ok, integrator_id, password} ->
            {:ok, %{integrator_id: integrator_id, password: password}}
          :error ->
            :error
        end
      :error ->
        :error
    end
  end

  defp get_basic_auth_header(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      [header | _] = _ ->
        case String.split(header, " ") do
          ["Basic", encoded_token] ->
            {:ok, encoded_token}
          _ ->
            :error
        end
      _ ->
        :error
    end
  end

  defp decode_basic_auth_token(encoded_token) do
    case Base.decode64(encoded_token) do
      {:ok, decoded_token} ->
        case String.split(decoded_token, ":") do
          [integrator_id, password] ->
            {:ok, integrator_id, password}
          _ ->
            :error
        end
      _ ->
        :error
    end
  end

end
