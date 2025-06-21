defmodule FinincialToolWeb.Auth.HubSpotStrategy do
  @moduledoc """
  Custom Ueberauth strategy for HubSpot OAuth2 integration.
  """

  use Ueberauth.Strategy, ignores_csrf_attack: true

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @defaults [
    site: "https://api.hubapi.com",
    authorize_url: "https://app.hubspot.com/oauth/authorize",
    token_url: "https://api.hubapi.com/oauth/v1/token"
  ]

  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)

    client_id = option(conn, :client_id)
    client_secret = option(conn, :client_secret)
    redirect_uri = callback_url(conn)

    # Use Ueberauth's built-in state handling
    state = conn.params["state"] || generate_state()

    # Debug logging
    IO.inspect(client_id, label: "HubSpot Client ID")
    IO.inspect(client_secret, label: "HubSpot Client Secret")
    IO.inspect(redirect_uri, label: "HubSpot Redirect URI")
    IO.inspect(scopes, label: "HubSpot Scopes")
    IO.inspect(state, label: "HubSpot State")

    client = OAuth2.Client.new([
      strategy: OAuth2.Strategy.AuthCode,
      client_id: client_id,
      client_secret: client_secret,
      site: option(conn, :site),
      authorize_url: option(conn, :authorize_url),
      token_url: option(conn, :token_url)
    ])

    params = [
      scope: scopes,
      redirect_uri: redirect_uri,
      state: state
    ]

    # Store state for Ueberauth's CSRF protection
    conn = conn |> put_session(:ueberauth_state, state)

    authorize_url = OAuth2.Client.authorize_url!(client, params)
    IO.inspect(authorize_url, label: "HubSpot Authorize URL")
    redirect!(conn, authorize_url)
  end

  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    IO.inspect(conn.params, label: "HubSpot Callback Params")

    client_id = option(conn, :client_id)
    client_secret = option(conn, :client_secret)
    redirect_uri = callback_url(conn)

    # Make token request directly to HubSpot
    token_params = %{
      grant_type: "authorization_code",
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri,
      code: code
    }

    IO.inspect(token_params, label: "HubSpot Token Request Params")

    case HTTPoison.post("https://api.hubapi.com/oauth/v1/token",
                       URI.encode_query(token_params),
                       [{"Content-Type", "application/x-www-form-urlencoded"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, token_data} ->
            IO.inspect(token_data, label: "HubSpot Token Response")

            # Create OAuth2.AccessToken struct
            token = %OAuth2.AccessToken{
              access_token: token_data["access_token"],
              refresh_token: token_data["refresh_token"],
              expires_at: token_data["expires_in"] && (System.system_time(:second) + token_data["expires_in"]),
              token_type: token_data["token_type"] || "bearer",
              other_params: token_data
            }

            fetch_user(conn, token)
          {:error, reason} ->
            IO.inspect(reason, label: "HubSpot Token JSON Decode Error")
            set_errors!(conn, [error("token", "invalid_json_response")])
        end
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.inspect({status_code, body}, label: "HubSpot Token HTTP Error")
        set_errors!(conn, [error("token", body)])
      {:error, reason} ->
        IO.inspect(reason, label: "HubSpot Token Request Error")
        set_errors!(conn, [error("token", "request_failed")])
    end
  end

  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No authorization code received")])
  end

  def handle_cleanup!(conn) do
    conn
    |> put_private(:hubspot_user, nil)
    |> put_private(:hubspot_token, nil)
  end

  def uid(conn) do
    conn.private.hubspot_user["user_id"] || conn.private.hubspot_user["hub_id"]
  end

  def credentials(conn) do
    token = conn.private.hubspot_token
    scope_string = (token.other_params["scope"] || "")
    scopes = String.split(scope_string, " ")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  def info(conn) do
    user = conn.private.hubspot_user

    %Info{
      name: user["user"] || "HubSpot User",
      email: user["user"] || user["hub_domain"],
      nickname: user["user"] || user["hub_domain"]
    }
  end

  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.hubspot_token,
        user: conn.private.hubspot_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :hubspot_token, token)

    # HubSpot doesn't provide a standard user info endpoint
    # We'll use the access token info endpoint to get basic details
    client = OAuth2.Client.new([
      site: option(conn, :site),
      token: token
    ])

    case OAuth2.Client.get(client, "/oauth/v1/access-tokens/" <> token.access_token) do
      {:ok, %OAuth2.Response{status_code: 401, body: body}} ->
        IO.inspect(body, label: "HubSpot 401 Error")
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %OAuth2.Response{status_code: status_code, body: user_json}} when status_code in 200..399 ->
        IO.inspect(user_json, label: "HubSpot User Info JSON")
        case Jason.decode(user_json) do
          {:ok, user_data} ->
            IO.inspect(user_data, label: "HubSpot User Info Parsed")
            put_private(conn, :hubspot_user, user_data)
          {:error, reason} ->
            IO.inspect(reason, label: "HubSpot User Info JSON Parse Error")
            set_errors!(conn, [error("fetch_user", "invalid_json_response")])
        end
      {:error, %OAuth2.Response{status_code: status_code, body: body}} ->
        IO.inspect({status_code, body}, label: "HubSpot HTTP Error")
        set_errors!(conn, [error("fetch_user", "HTTP #{status_code}: #{inspect(body)}")])
      {:error, %OAuth2.Error{reason: reason}} ->
        IO.inspect(reason, label: "HubSpot OAuth2 Error")
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp generate_state do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  defp option(conn, key) do
    case key do
      :client_id -> System.get_env("HUBSPOT_CLIENT_ID")
      :client_secret -> System.get_env("HUBSPOT_CLIENT_SECRET")
      _ -> Keyword.get(options(conn), key, Keyword.get(@defaults, key))
    end
  end
end
