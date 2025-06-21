defmodule FinincialTool.Accounts do
  import Ecto.Query, warn: false
  # import FinincialToolWeb.Helps.DataTable, only: [sort: 1]
  @pagination [page_size: 10]

  alias FinincialTool.Repo
  alias FinincialTool.Logs
  alias FinincialTool.Settings
  alias FinincialTool.Accounts.User
  alias FinincialTool.Accounts.UserToken
  alias FinincialTool.Workers.Util.Utils
  alias FinincialTool.Utils.NumberFunctions

  # FinincialTool.Accounts.update_all_user_pwds()
  def update_all_user_pwds() do
    users = Repo.all(User)

    Enum.each(users, fn user ->
      Repo.update(
        User.update_password_changeset(user, %{
          blocked: false,
          login_attempts: 0,
          password: "password06"
        })
      )
    end)
  end

  def get_user_by_auth_id(username) do
    User
    |> where([a], a.username == ^username)
    |> Repo.all()
    |> List.first()
  end

  # FinincialTool.Accounts.list_tbl_users()
  def list_tbl_users do
    Repo.all(User)
  end
  # FinincialTool.Accounts.get_user!
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_id(id) do
    User
    |> where([a], a.id == ^id)
    |> select([a], a)
    |> preload([:role])
    |> Repo.one()
  end

  def get_user_details(id) do
    User
    |> where([a], a.id == ^id)
    |> select([a], a)
    |> preload([:role])
    |> Repo.all()
  end

  def get_emp_user(id) do
    em_id = String.to_integer(id)

    User
    |> join(:left, [a], b in "tbl_employee_accounts", on: a.id == b.employee_id)
    |> where([_a, b], b.employee_id == ^em_id)
    |> select([a], a)
    |> preload([:role])
    |> Repo.one()
  end

  def get_emp_user_by_id(user_id) do
    User
    |> where([a], a.id == ^user_id)
    |> limit(1)
    |> Repo.one()
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def multi_update_user(user, attrs), do: User.update_changeset(user, attrs)

  def update_user_details(attrs, multiple \\ Ecto.Multi.new()) do
    Ecto.Multi.run(multiple, :user, fn _, _ -> {:ok, get_user!(attrs["id"])} end)
    |> Ecto.Multi.update(
      :update,
      fn %{user: user} ->
        multi_update_user(user, attrs)
      end
    )
    |> Repo.transaction()
  end

  def update_user(user, attrs) do
    multi_update_user(user, attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def login_user(%User{} = user, attrs \\ %{}) do
    User.login_changeset(user, attrs)
  end

  def password_changeset(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  def get_by_username(username) do
    User
    |> where([a], a.username == ^username)
    |> Repo.all()
    |> List.first()
  end

  def get_user_by_email(email) do
    User
    |> where([a], a.email == ^email)
    |> Repo.one()
  end

  def get_user_by_username_and_password(conn, username, password)
      when is_binary(username) and is_binary(password) do
    get_by_username(username)
    |> case do
      nil ->
        {:error, "User not found!!"}

      user ->
        cond do
          user.blocked ->
            {:error, "User Account Blocked. Please contact system administrator"}

          user.status == "ACTIVE" ->
            case User.valid_password?(user, password) do
              true ->
                {:ok, _} = Logs.create_user_logs(%{user_id: user.id, activity: "logged in"})
                user

              false ->
                Task.start(fn -> update_user_login_attempts(conn, user) end)
                {:error, "Invalid Username or Password!!"}
            end

          true ->
            {:error, "Failed login, contact system administrator"}
        end
    end
  end

  defp update_user_login_attempts(_conn, user) do
    setting = Settings.get_setting_configuration("login_failed_attempts_max")
    failed_attempts = NumberFunctions.convert_to_int(setting.value)

    if user.failed_attempts == failed_attempts do
      Repo.update(User.update_changeset(user, %{blocked: true}))
    else
      Repo.update(User.update_changeset(user, %{failed_attempts: user.failed_attempts + 1}))
    end
  end

  def list_client_users(search_params) do
    User
    |> where([u], u.status != "DELETED" and u.user_type in ["EMPLOYER", "CLIENT"])
    |> handle_user_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_user_select()
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  def list_system_users(search_params, user_type) do
    User
    |> join(:left, [u], r in "tbl_user_role", on: u.role_id == r.id)
    |> where([u], u.status != "DELETED" and u.user_type == ^user_type and u.blocked == false)
    |> handle_user_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_user_select()
    |> select_merge([_u, r], %{user_role: r.name})
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  def get_blocked_users(search_params, _user_type) do
    User
    |> join(:left, [u], r in "tbl_user_role", on: u.role_id == r.id)
    |> where([u], u.status == "ACTIVE" and u.blocked == true)
    |> handle_user_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_user_select()
    |> select_merge([_u, r], %{user_role: r.name})
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp handle_user_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        user_isearch_filter(query, Utils.sanitize_term(value))

      {"first_name", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.first_name, ^Utils.sanitize_term(value))
        )

      {"last_name", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.last_name, ^Utils.sanitize_term(value))
        )

      {"username", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.username, ^Utils.sanitize_term(value))
        )

      {"user_type", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.user_type, ^Utils.sanitize_term(value))
        )

      {"name", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [_a, r],
          fragment("lower(?) LIKE lower(?)", r.name, ^Utils.sanitize_term(value))
        )

      {"sex", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("lower(?) LIKE lower(?)", a.sex, ^Utils.sanitize_term(value)))

      {"phone", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.phone, ^Utils.sanitize_term(value))
        )

      {"email", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.email, ^Utils.sanitize_term(value))
        )

      {"from", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("CAST(? AS DATE) >= ?", a.inserted_at, ^value))

      {"to", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("CAST(? AS DATE) <= ?", a.inserted_at, ^value))

      {_, _}, query ->
        # Not a where parameter
        query
    end)
  end

  defp user_isearch_filter(query, search_term) do
    where(
      query,
      [a],
      fragment("lower(?) LIKE lower(?)", a.first_name, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.last_name, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.username, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.phone, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.sex, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.user_type, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.email, ^search_term)
    )
  end

  defp compose_user_select(query) do
    query
    |> select(
      [u, r],
      map(u, [
        :id,
        :first_name,
        :last_name,
        :username,
        :email,
        :password,
        :hashed_password,
        :sex,
        :dob,
        :id_no,
        :phone,
        :address,
        :status,
        :blocked,
        :user_type,
        :user_class,
        :failed_attempts,
        :confirmed_at,
        :approved_at,
        :last_login,
        :maker_id,
        :updated_by,
        :role_id,
        :inserted_at,
        :updated_at
      ])
    )
  end

  def get_anouncement_recipient(recipient) do
    case recipient do
      "ALL" -> Repo.all(from m in User, where: m.status == "ACTIVE")
      _ -> Repo.all(from m in User, where: m.status == "ACTIVE" and m.user_type == ^recipient)
    end
  end

  # ====================================== UserToken ============================

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    # notify_subs({:ok, %{}}, :updated, @topic1)
    {}
    token
  end

  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    |> case do
      {1, nil} ->
        # notify_subs({:ok, %{}}, :updated, @topic1)
        :ok

      _ ->
        :ok
    end

    :ok
  end

  def get_session_by_user_id(id) do
    UserToken
    |> where([a], a.user_id == ^id)
    |> Repo.all()
  end

  def get_user_by_session_token(token, type) do
    {:ok, query} = UserToken.verify_session_token_query(token, type)
    Repo.one(query)
  end

  # defp notify_subs({:ok, _result}, _event, _topic) do
  #   {:ok, ""}
  # end

  # defp notify_subs({:error, result}, _event, _), do: {:error, traverse_errors(result.errors)}

  # defp notify_subs({:error, _failed_operation, failed_value, _changes_so_far}, _event, _),
  #   do: {:error, traverse_errors(failed_value.errors)}

  def traverse_errors(errors),
    do: for({key, {msg, _opts}} <- errors, do: "#{key} #{msg}") |> List.first()

  def list_tbl_user_token do
    Repo.all(UserToken)
  end

  def get_user_token!(id), do: Repo.get!(UserToken, id)

  def delete_user_token(%UserToken{} = user_token) do
    Repo.delete(user_token)
  end

  # FinincialTool.Accounts.count_clients
  def count_users() do
    User
    |> where([mx], mx.user_type == "BACKOFFICE")
    |> Repo.aggregate(:count)
  end

  # ================== Generate Username ======================
  # FinincialTool.Accounts.generate_unique_username("admin", "admin")
  def generate_unique_username(first_name, last_name) do
    base_usernames = [
      String.downcase(first_name),
      String.downcase(last_name),
      "#{String.downcase(first_name)}#{String.downcase(last_name)}"
    ]

    find_unique_username(base_usernames, 0)
  end

  defp find_unique_username([base | rest], count) when count <= 100 do
    username =
      if count == 0 do
        base
      else
        "#{base}#{count}"
      end

    case Repo.get_by(User, username: username) do
      nil ->
        username

      _user ->
        find_unique_username([base | rest], count + 1)
    end
  end

  defp find_unique_username([], _count) do
    generate_random_username()
  end

  defp find_unique_username([_base | rest], 101) do
    find_unique_username(rest, 0)
  end

  defp generate_random_username() do
    random_username = "user_" <> random_string(6)

    case Repo.get_by(User, username: random_username) do
      nil -> random_username
      # Retry if random username already exists
      _user -> generate_random_username()
    end
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode32(case: :lower)
    |> binary_part(0, length)
  end

  def unique_query(field, representative_module) do
    users_query = from(u in User, select: %{^field => field(u, ^field)})

    representatives_query =
      from(r in representative_module, select: %{^field => field(r, ^field)})

    from(q in subquery(users_query |> union(^representatives_query)),
      select: %{^field => field(q, ^field)}
    )
  end
end
