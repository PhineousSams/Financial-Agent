defmodule FinancialAgent.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query

  alias FinancialAgent.Settings
  alias FinancialAgent.Accounts.{User, UserToken}
  alias FinancialAgent.Utils.NumberFunctions

  @hash_algorithm :sha256
  @rand_size 32

  # It is very important to keep the reset password token expiry short,
  # since someone with access to the email may take over the account.
  @reset_password_validity_in_days 10 / 1440
  @confirm_validity_in_days 7
  @change_email_validity_in_days 7
  @session_validity_in_days 60

  schema "tbl_user_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    field :login_timestamp, :naive_datetime
    belongs_to :user, User

    timestamps(updated_at: false)
  end

  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %UserToken{token: token, context: "session", user_id: user.id}}
  end

  def verify_session_token_query(token, type) do
    IO.inspect type, label: "=========== type"
    setting = Settings.get_setting_configuration("user_inactive_session_notification")
    _setting1 = Settings.get_setting_configuration("inactive_user_model_timeout")

    session_validity_in_days1 =
      NumberFunctions.convert_to_int(setting.value) || @session_validity_in_days

    session_validity_in_days2 =
      NumberFunctions.convert_to_int(setting.value) || @session_validity_in_days

    session_validity_in_days = session_validity_in_days1 + session_validity_in_days2

    period =
      if setting.value_type == nil,
        do: String.replace(setting.value_type, "s", ""),
        else: "minute"

    query =
      case type do
        "ADMIN" ->
          from token in token_and_context_query(token, "session"),
            join: user in assoc(token, :user),
            join: role in assoc(user, :role),
            where: token.inserted_at > ago(^session_validity_in_days, ^period),
            select: {user, role}

        _ ->
          from token in token_and_context_query(token, "session"),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^session_validity_in_days, ^period),
            select: user
      end

    {:ok, query}
  end

  @doc """
  Builds a token with a hashed counter part.

  The non-hashed token is sent to the user email while the
  hashed part is stored in the database, to avoid reconstruction.
  The token is valid for a week as long as users don't change
  their email.
  """
  def build_email_token(user, context) do
    build_hashed_token(user, context, user.email)
  end

  def build_reset_password_token(user) do
    build_hashed_token(user, "reset_password", user.email)
  end

  # defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  def verify_reset_password_token_query(token) do
    verify_email_token_query(token, "reset_password")
  end

  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %UserToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token.
  """
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from token in token_and_context_query(hashed_token, context),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == user.email,
            select: user

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user token record.
  """
  def verify_change_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_email_validity_in_days, "day")

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Returns the given token with the given context.
  """
  def token_and_context_query(token, context) do
    from UserToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  def user_and_contexts_query(user, :all) do
    from t in UserToken, where: t.user_id == ^user.id
  end

  def user_and_contexts_query(user, [_ | _] = contexts) do
    from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
  end
end
