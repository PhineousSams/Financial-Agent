defmodule FinancialAgent.Auth.OAuthToken do
  use Ecto.Schema
  import Ecto.Changeset

  alias FinancialAgent.Accounts.User

  schema "oauth_tokens" do
    field :provider, :string
    field :access_token, :string
    field :refresh_token, :string
    field :expires_at, :utc_datetime
    field :scope, :string
    field :token_type, :string, default: "Bearer"

    belongs_to :user, User, foreign_key: :user_id, references: :id

    timestamps()
  end

  @doc false
  def changeset(oauth_token, attrs) do
    oauth_token
    |> cast(attrs, [:user_id, :provider, :access_token, :refresh_token, :expires_at, :scope, :token_type])
    |> validate_required([:user_id, :provider, :access_token])
    |> validate_inclusion(:provider, ["google", "hubspot"])
    |> unique_constraint([:user_id, :provider])
    |> foreign_key_constraint(:user_id)
  end

  def expired?(%__MODULE__{expires_at: nil}), do: false
  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  def needs_refresh?(%__MODULE__{} = token) do
    expired?(token) and not is_nil(token.refresh_token)
  end
end
