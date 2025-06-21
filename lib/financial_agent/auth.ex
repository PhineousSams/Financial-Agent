defmodule FinincialAgent.Auth do
  @moduledoc """
  The Auth context for managing OAuth tokens and authentication.
  """

  import Ecto.Query, warn: false
  alias FinincialAgent.Repo
  alias FinincialAgent.Auth.OAuthToken

  @doc """
  Gets an OAuth token for a user and provider.
  """
  def get_oauth_token(user_id, provider) do
    OAuthToken
    |> where([t], t.user_id == ^user_id and t.provider == ^provider)
    |> Repo.one()
  end

  @doc """
  Creates or updates an OAuth token.
  """
  def upsert_oauth_token(attrs) do
    case get_oauth_token(attrs.user_id, attrs.provider) do
      nil ->
        %OAuthToken{}
        |> OAuthToken.changeset(attrs)
        |> Repo.insert()

      existing_token ->
        existing_token
        |> OAuthToken.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Refreshes an OAuth token if needed.
  """
  def refresh_token_if_needed(%OAuthToken{} = token) do
    if OAuthToken.needs_refresh?(token) do
      case refresh_oauth_token(token) do
        {:ok, refreshed_token} -> {:ok, refreshed_token}
        {:error, reason} -> {:error, reason}
      end
    else
      {:ok, token}
    end
  end

  @doc """
  Refreshes an OAuth token using the refresh token.
  """
  def refresh_oauth_token(%OAuthToken{provider: "google"} = token) do
    # Implement Google token refresh
    refresh_google_token(token)
  end

  def refresh_oauth_token(%OAuthToken{provider: "hubspot"} = token) do
    # Implement HubSpot token refresh
    refresh_hubspot_token(token)
  end

  defp refresh_google_token(%OAuthToken{} = token) do
    # This would implement the actual Google OAuth refresh logic
    # For now, return the token as-is
    {:ok, token}
  end

  defp refresh_hubspot_token(%OAuthToken{} = token) do
    # This would implement the actual HubSpot OAuth refresh logic
    # For now, return the token as-is
    {:ok, token}
  end

  @doc """
  Deletes an OAuth token.
  """
  def delete_oauth_token(%OAuthToken{} = token) do
    Repo.delete(token)
  end

  @doc """
  Lists all OAuth tokens for a user.
  """
  def list_user_oauth_tokens(user_id) do
    OAuthToken
    |> where([t], t.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Checks if a user has connected a specific provider.
  """
  def provider_connected?(user_id, provider) do
    case get_oauth_token(user_id, provider) do
      nil -> false
      _token -> true
    end
  end
end
