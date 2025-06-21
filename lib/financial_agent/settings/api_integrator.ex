defmodule FinincialAgent.Settings.ApiIntegrator do
  use Ecto.Schema
  import Ecto.Changeset

  alias FinincialAgent.Accounts.User
  alias FinincialAgent.Settings.ApiIntegrator

  @columns ~w(id name status integrator_id callback_url endpoint auth_token expires_at revoked_at password password_hash attempt_count contact_email
    maker_id checker_id inserted_at updated_at ip_address port
  )a
  @derive {Jason.Encoder, only: @columns}
  schema "tbl_api_integrators" do
    field :password, :string, virtual: true, redact: false

    field :name, :string
    field :integrator_id, Ecto.UUID, autogenerate: true
    field :callback_url, :string
    field :endpoint, :string
    field :auth_token, :string
    field :expires_at, :utc_datetime
    field :revoked_at, :utc_datetime
    field :status, :string, default: "ACTIVE"
    field :password_hash, :string
    field :attempt_count, :integer, default: 0
    field :contact_email, :string
    field :ip_address, :string
    field :port, :integer

    belongs_to :maker, User, foreign_key: :maker_id, type: :id
    belongs_to :checker, User, foreign_key: :checker_id, type: :id

    timestamps()
  end

  @doc false
  def changeset(api_integrator, attrs) do
    api_integrator
    |> cast(attrs, @columns)
    |> validate_required([:name, :integrator_id, :status, :endpoint, :maker_id])
    |> unique_constraint(:integrator_id)
    |> unique_constraint(:name)
  end

  def update_changeset(api_integrator, attrs, opts \\ []) do
    api_integrator
    |> cast(attrs,[:integrator_id, :password_hash, :password])
    |> validate_password(opts)
  end


  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 10, max: 80)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:password_hash, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def valid_password?(%ApiIntegrator{password_hash: password_hash}, password)
      when is_binary(password_hash) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, password_hash)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end
end
