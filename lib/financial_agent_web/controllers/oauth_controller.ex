defmodule FinincialToolWeb.OAuthController do
  use FinincialToolWeb, :controller

  alias FinincialTool.Auth
  alias FinincialTool.Auth.OAuthToken

  plug Ueberauth

  def request(conn, %{"provider" => provider}) do
    # This will redirect to the OAuth provider
    # Ueberauth handles the redirect automatically
    conn
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => "google"}) do
    case handle_google_login(auth, conn) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully signed in with Google!")
        |> FinincialToolWeb.Plugs.UserAuth.log_in_user(user, %{})

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to sign in with Google: #{reason}")
        |> redirect(to: "/")
    end
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => provider}) do
    # Handle other OAuth providers (like HubSpot) for service connections
    case get_current_user_id(conn) do
      nil ->
        conn
        |> put_flash(:error, "Please sign in first before connecting #{String.capitalize(provider)}")
        |> redirect(to: "/")

      user_id ->
        case handle_oauth_callback(auth, provider, user_id) do
          {:ok, _token} ->
            conn
            |> put_flash(:info, "Successfully connected #{String.capitalize(provider)}!")
            |> redirect(to: "/Admin/chats")

          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to connect #{String.capitalize(provider)}: #{reason}")
            |> redirect(to: "/Admin/chats")
        end
    end
  end

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, %{"provider" => provider}) do
    errors = failure.errors |> Enum.map(& &1.message) |> Enum.join(", ")
    IO.inspect(failure, label: "OAuth Failure for #{provider}")

    conn
    |> put_flash(:error, "Authentication failed for #{String.capitalize(provider)}: #{errors}")
    |> redirect(to: "/")
  end

  def callback(conn, %{"provider" => provider}) do
    IO.inspect(conn.assigns, label: "OAuth Callback Assigns for #{provider}")

    conn
    |> put_flash(:error, "Authentication failed for #{String.capitalize(provider)}")
    |> redirect(to: "/")
  end

  defp handle_oauth_callback(%Ueberauth.Auth{} = auth, "google", user_id) do
    %{
      credentials: %{
        token: access_token,
        refresh_token: refresh_token,
        expires_at: expires_at,
        scopes: scopes
      }
    } = auth

    token_attrs = %{
      user_id: user_id,
      provider: "google",
      access_token: access_token,
      refresh_token: refresh_token,
      expires_at: expires_at && DateTime.from_unix!(expires_at),
      scope: Enum.join(scopes || [], " ")
    }

    Auth.upsert_oauth_token(token_attrs)
  end

  defp handle_oauth_callback(%Ueberauth.Auth{} = auth, "hubspot", user_id) do
    %{
      credentials: %{
        token: access_token,
        refresh_token: refresh_token,
        expires_at: expires_at,
        scopes: scopes
      }
    } = auth

    token_attrs = %{
      user_id: user_id,
      provider: "hubspot",
      access_token: access_token,
      refresh_token: refresh_token,
      expires_at: expires_at && DateTime.from_unix!(expires_at),
      scope: Enum.join(scopes || [], " ")
    }

    Auth.upsert_oauth_token(token_attrs)
  end

  defp handle_oauth_callback(_auth, provider, _user_id) do
    {:error, "Unsupported provider: #{provider}"}
  end

  defp handle_google_login(%Ueberauth.Auth{} = auth, _conn) do
    %{
      info: %{
        email: email,
        first_name: first_name,
        last_name: last_name,
        name: name
      },
      credentials: %{
        token: access_token,
        refresh_token: refresh_token,
        expires_at: expires_at,
        scopes: scopes
      }
    } = auth

    # Find or create user based on Google email
    case find_or_create_google_user(email, first_name, last_name, name) do
      {:ok, user} ->
        # Store Google OAuth token for this user
        token_attrs = %{
          user_id: user.id,
          provider: "google",
          access_token: access_token,
          refresh_token: refresh_token,
          expires_at: expires_at && DateTime.from_unix!(expires_at),
          scope: Enum.join(scopes || [], " ")
        }

        case Auth.upsert_oauth_token(token_attrs) do
          {:ok, _token} -> {:ok, user}
          {:error, reason} -> {:error, "Failed to store OAuth token: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, "Failed to create user: #{inspect(reason)}"}
    end
  end

  defp find_or_create_google_user(email, first_name, last_name, name) do
    alias FinincialTool.Accounts
    alias FinincialTool.Accounts.User

    # Try to find existing user by email
    case Accounts.get_user_by_email(email) do
      nil ->
        # Create new user
        user_attrs = %{
          email: email,
          first_name: first_name || extract_first_name(name),
          last_name: last_name || extract_last_name(name),
          username: email,
          password: "password06",
          auto_pwd: false,
          sex: "M",
          dob: Date.utc_today(),
          id_no: "GOOGLE_#{:crypto.strong_rand_bytes(8) |> Base.encode16()}",
          phone: "260974989898",
          status: "ACTIVE",
          user_status: "ACTIVE",
          blocked: false,
          user_type: "BACKOFFICE",
          role_id: 1
        }

        case Accounts.create_user(user_attrs) do
          {:ok, user} -> {:ok, user}
          {:error, changeset} -> {:error, changeset}
        end

      user ->
        # Update existing user's name if needed
        updates = %{}
        updates = if first_name && user.first_name != first_name, do: Map.put(updates, :first_name, first_name), else: updates
        updates = if last_name && user.last_name != last_name, do: Map.put(updates, :last_name, last_name), else: updates

        if map_size(updates) > 0 do
          case Accounts.update_user(user, updates) do
            {:ok, updated_user} -> {:ok, updated_user}
            {:error, _changeset} -> {:ok, user} # Return original user if update fails
          end
        else
          {:ok, user}
        end
    end
  end

  defp extract_first_name(name) when is_binary(name) do
    name |> String.split(" ") |> List.first() || ""
  end
  defp extract_first_name(_), do: ""

  defp extract_last_name(name) when is_binary(name) do
    parts = String.split(name, " ")
    if length(parts) > 1, do: Enum.join(Enum.drop(parts, 1), " "), else: ""
  end
  defp extract_last_name(_), do: ""

  defp get_current_user_id(conn) do
    case conn.assigns[:current_user] do
      nil -> nil
      user -> user.id
    end
  end
end
