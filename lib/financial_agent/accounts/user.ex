defmodule FinancialAgent.Accounts.User do
  use Endon
  use Ecto.Schema
  import Ecto.Changeset

  alias FinancialAgent.Repo
  alias FinancialAgent.Accounts.User
  alias FinancialAgent.Roles.UserRole
  alias FinancialAgent.Centres.Provincial

  @columns ~w(title first_name last_name other_name username email password auto_pwd sex dob id_no
  phone address status blocked user_type user_class failed_attempts pwd_reuse  maker_id updated_by approved_at
  confirmed_at last_login role_id inserted_at updated_at plot_number street_name area
  accomodation_status resedential_years remark)a

  @derive {Jason.Encoder, only: @columns}
  @derive {Inspect, except: [:password]}
  schema "tbl_user" do
    field :current_password, :string, virtual: true, redact: true
    field :new_password, :string, virtual: true, redact: true
    field :confirm_password, :string, virtual: true, redact: true

    field :title, :string
    field :first_name, :string
    field :last_name, :string
    field :username, :string
    field :other_name, :string
    field :email, :string
    field :password, :string
    field :hashed_password
    field :auto_pwd, :boolean, default: true
    field :sex, :string
    field :dob, :date
    field :id_no, :string
    field :phone, :string
    field :address, :string
    field :status, :string
    field :blocked, :boolean
    field :user_type, :string
    field :user_class, :string
    field :failed_attempts, :integer
    field :pwd_reuse, :integer, default: 0
    field :area, :string
    field :plot_number, :string
    field :street_name, :string
    field :resedential_years, :integer
    field :accomodation_status, :string
    field :approved_at, :naive_datetime
    field :confirmed_at, :naive_datetime
    field :last_login, :naive_datetime

    belongs_to :maker, User, foreign_key: :maker_id, type: :id
    belongs_to :checker, User, foreign_key: :updated_by, type: :id
    belongs_to :role, UserRole, foreign_key: :role_id, type: :id

    timestamps(type: :utc_datetime)
    field :remark, :string
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, @columns)
    |> validate_field_sizes()
    |> validate_email()
    |> validate_username()
    |> validate_password(opts)
  end

  def changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, @columns)
    |> validate_field_sizes()
    |> validate_email()
    |> validate_username()
    |> validate_password(opts)
  end

  def login_changeset(user, attrs, _opts \\ []) do
    user
    |> cast(attrs, @columns)
    |> validate_required([:password, :username])
  end

  def change_password_changeset(user, attrs, _opts \\ []) do
    user
    |> cast(attrs, [:current_password, :new_password, :confirm_password])
    |> validate_required([:current_password, :new_password, :confirm_password])
  end

  def update_password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, @columns)
    |> validate_password(opts)
  end

  def update_changeset(user, attrs, _opts \\ []) do
    user
    |> cast(attrs, @columns)
    |> unique_constraint(:username)
    |> validate_email()
    |> validate_username()
  end

  def approve_changeset(user, attrs, _opts \\ []) do
    user
    |> cast(attrs, [:status, :updated_by])
    |> validate_required(:status)
  end

  def validate_field_sizes(changeset) do
    changeset
    |> validate_required([:password, :username, :last_name, :first_name, :phone])
    |> validate_length(:username, max: 30)
    |> validate_length(:first_name, max: 30)
    |> validate_length(:last_name, max: 30)
    |> validate_length(:email, max: 80)
    |> validate_length(:id_no, max: 30)
    |> validate_length(:phone, max: 12)
    |> validate_length(:address, max: 100)
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 3)
    |> unsafe_validate_unique(:username, Repo)
    |> unique_constraint(:username)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 80)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Pbkdf2.hash_pwd_salt(password))
      |> put_change(:password, Pbkdf2.hash_pwd_salt(password))

      # |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Pbkdf2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
  end

  def valid_password?(%{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def change_password_validation(user, password, new_pass, confirm_pwd) do
    case valid_password?(user, password) do
      true ->
        case valid_password?(user, new_pass) do
          false ->
            case compare_passwords(new_pass, confirm_pwd) do
              true ->
                {:ok, user}

              false ->
                {:error, "New password and password confirmation does not match."}
            end

          true ->
            {:error, "New password should be different from the current password."}
        end

      false ->
        {:error, "The current password is wrong, please enter the correct password."}
    end
  end

  def validate_passwords(user, password, new_pass, confirm_pwd, config) do
    value = config.reuse

    case valid_password?(user, password) do
      true ->
        case valid_password?(user, new_pass) do
          false ->
            case compare_passwords(new_pass, confirm_pwd) do
              true ->
                {:ok, user}

              false ->
                {:error, "New password and password confirmation does not match."}
            end

          true ->
            case user.pwd_reuse <= value do
              true -> {:ok, user}
              false -> {:error, "New password should be different from the current password."}
            end
        end

      false ->
        {:error, "The current password is wrong, please enter the correct password."}
    end
  end

  def validate_passwords(user, new_pass, confirm_pwd, config) do
    value = config.reuse

    case valid_password?(user, new_pass) do
      false ->
        case compare_passwords(new_pass, confirm_pwd) do
          true ->
            {:ok, user}

          false ->
            {:error, "New password and password confirmation does not match."}
        end

      true ->
        case user.pwd_reuse <= value do
          true -> {:ok, user}
          false -> {:error, "New password should be different from the current password."}
        end
    end
  end

  def compare_passwords(new_pass, confirm_pwd) do
    new_pass_hash = Pbkdf2.hash_pwd_salt(new_pass)
    Pbkdf2.verify_pass(confirm_pwd, new_pass_hash)
  end

  # FinancialAgent.Accounts.User.Localtime

  defmodule Localtime do
    def autogenerate, do: Timex.local() |> DateTime.truncate(:second) |> DateTime.to_naive()
  end

  def forgot_password_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 20)

    # |> validate_user_exists()
  end
end
