defmodule FinancialAgent.Settings do
  import Ecto.Query, warn: false
  @pagination [page_size: 10]

  alias FinancialAgent.Repo
  alias FinancialAgent.Workers.Util.Utils
  alias FinancialAgent.Settings.SmsConfigs
  alias FinancialAgent.Utils.NumberFunctions
  alias FinancialAgent.Settings.ConfigSettings
  alias FinancialAgent.Settings.DashboardStats
  alias FinancialAgent.Settings.ApiIntegrator

  def list_settings(search_params) do
    ConfigSettings
    |> handle_settings_filter(search_params)
    |> order_by(asc: :id)
    |> compose_settings_select()
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp handle_settings_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        settings_isearch_filter(query, Utils.sanitize_term(value))

      {"name", value}, query when byte_size(value) > 0 ->
        where(query, [e], fragment("lower(?) LIKE lower(?)", e.name, ^Utils.sanitize_term(value)))

      {"value", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [e],
          fragment("lower(?) LIKE lower(?)", e.value, ^Utils.sanitize_term(value))
        )

      {"value_type", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [_u, e],
          fragment("lower(?) LIKE lower(?)", e.value_type, ^Utils.sanitize_term(value))
        )

      {"description", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [_u, e],
          fragment("lower(?) LIKE lower(?)", e.description, ^Utils.sanitize_term(value))
        )

      {_, _}, query ->
        # Not a where parameter
        query
    end)
  end

  defp settings_isearch_filter(query, search_term) do
    where(
      query,
      [e],
      fragment("lower(?) LIKE lower(?)", e.name, ^search_term) or
        fragment("lower(?) LIKE lower(?)", e.value, ^search_term) or
        fragment("lower(?) LIKE lower(?)", e.value_type, ^search_term) or
        fragment("lower(?) LIKE lower(?)", e.description, ^search_term)
    )
  end

  def compose_settings_select(query) do
    query
    |> select(
      [a],
      map(a, [
        :id,
        :name,
        :value,
        :value_type,
        :description,
        :updated_by,
        :deleted_at
      ])
    )
  end

  def change_settings(%ConfigSettings{} = settings, attrs \\ %{}) do
    ConfigSettings.changeset(settings, attrs)
  end

  def list_settings do
    Repo.all(ConfigSettings)
  end

  def list_workflows do
    Repo.all(
      from c in ConfigSettings,
        where: c.value_type == "workflows",
        select: {c.name, c.id}
    )
  end

  def get_settings!(id), do: Repo.get!(ConfigSettings, id)

  def get_settings_by_type(type) do
    ConfigSettings
    |> where([w], w.value_type == ^type)
    |> Repo.one()
  end

  def create_settings(attrs \\ %{}) do
    %ConfigSettings{}
    |> ConfigSettings.changeset(attrs)
    |> Repo.insert()
  end

  def update_settings(%ConfigSettings{} = system, attrs) do
    system
    |> ConfigSettings.changeset(attrs)
    |> Repo.update()
  end

  def get_license_approval_configs() do
    ConfigSettings
    |> where([a], a.name == "license_auth_levels")
    |> Repo.all()
    |> List.last()
  end

  def get_setting_configuration(name) do
    settings = Repo.get_by(ConfigSettings, name: name)
    if settings == nil, do: %ConfigSettings{}, else: settings
  end

  def get_setting_value_name(type, name) do
    ConfigSettings
    |> where([s], s.value_type == ^type and s.name == ^name)
    |> limit(1)
    |> Repo.one()
  end

  def get_setting_value_type(type) do
    ConfigSettings
    |> where([s], s.value_type == ^type)
    |> order_by(asc: :id)
    |> limit(1)
    |> Repo.one()
  end

  def get_all_settings_configuration do
    ConfigSettings_conf
    |> order_by(asc: :id)
    |> Repo.all()
  end

  def search_for_name_configuration(query) do
    ConfigSettings
    |> where([a], like(a.name, ^"%#{query}%"))
    |> order_by(asc: :id)
    |> Repo.all()
  end

  def update_config_settings_value(list) do
    list
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {attrs, index}, multi ->
      Ecto.Multi.run(multi, {:settings, index}, fn _repo, _ ->
        {:ok, Repo.get(ConfigSettings, attrs.id)}
      end)
      |> Ecto.Multi.update({:update, index}, fn all ->
        settings = all[{:settings, index}]
        ConfigSettings.changeset(settings, attrs)
      end)
    end)
    |> Repo.transaction()
  end

  def date_time_calculator(setting) do
    value = NumberFunctions.convert_to_int(setting.value || "0.0")

    case setting.value_type do
      #      "years" -> value * 60 * 60 * 24 * 12
      "days" -> value * 60 * 60 * 24
      "hours" -> value * 60 * 60
      "minutes" -> value * 60
      "seconds" -> value
      _ -> value
    end
  end


  # ======== SMS CONFIG ===============

  def change_sms_config(%SmsConfigs{} = sms_configs, attrs \\ %{}) do
    SmsConfigs.changeset(sms_configs, attrs)
  end

  def create_config(attrs) do
    changeset = SmsConfigs.changeset(%SmsConfigs{}, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:create_config, changeset, [])
    |> Repo.transaction()
  end

  def update_config(config, attrs) do
    changeset = SmsConfigs.changeset(config, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:update_config, changeset)
    |> Repo.transaction()
  end

  def get_sms_config!(id) do
    SmsConfigs
    |> Repo.get_by!(id: id)
  end

  def list_sms_settings(search_params) do
    SmsConfigs
    |> where([a], a.status != "DELETED")
    |> handle_sms_settings_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_sms_settings_select()
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp handle_sms_settings_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        sms_settings_isearch_filter(query, Utils.sanitize_term(value))

      {"username", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.username, ^Utils.sanitize_term(value))
        )

      {"password", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.password, ^Utils.sanitize_term(value))
        )

      {"host", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("lower(?) LIKE lower(?)", a.host, ^Utils.sanitize_term(value)))

      {"status", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.status, ^Utils.sanitize_term(value))
        )

      {"sender", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.sender, ^Utils.sanitize_term(value))
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

  defp sms_settings_isearch_filter(query, search_term) do
    where(
      query,
      [a],
      fragment("lower(?) LIKE lower(?)", a.username, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.password, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.host, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.status, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.sender, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.status, ^search_term)
    )
  end

  defp compose_sms_settings_select(query) do
    query
    |> select(
      [a],
      map(a, [
        :id,
        :username,
        :password,
        :status,
        :host,
        :sender,
        :status,
        :max_attempts,
        :inserted_at,
        :updated_at
      ])
    )
  end

  # ============ DASHBOARD STATS ===========

  # ========== Cache =============
  def get_by_name(name) do
    DashboardStats
    |> where([a], a.name == ^name)
    |> Repo.one()
  end

  def get_dashboard_data() do
    DashboardStats
    |> Repo.all()
  end

  def list_tbl_dashboard_stats do
    Repo.all(DashboardStats)
  end

  def get_dashboard_stats!(id), do: Repo.get!(DashboardStats, id)

  def create_dashboard_stats(attrs \\ %{}) do
    %DashboardStats{}
    |> DashboardStats.changeset(attrs)
    |> Repo.insert()
  end

  def update_dashboard_stats(%DashboardStats{} = dashboard_stats, attrs) do
    dashboard_stats
    |> DashboardStats.changeset(attrs)
    |> Repo.update()
  end

  def delete_dashboard_stats(%DashboardStats{} = dashboard_stats) do
    Repo.delete(dashboard_stats)
  end

  def change_dashboard_stats(%DashboardStats{} = dashboard_stats, attrs \\ %{}) do
    DashboardStats.changeset(dashboard_stats, attrs)
  end







  # ============ ApiIntegrator ===================

  def get_bill_integrators(search_params) do
    ApiIntegrator
    |> join(:left, [s], m in assoc(s, :maker))
    |> join(:left, [s, m], c in assoc(s, :checker))
    |> handle_integrator_filter(search_params)
    |> order_by([s], desc: s.inserted_at)
    |> compose_integrator_select()
    |> select_merge([s, m, c], %{
      maker_name: fragment("CONCAT(?, ' ', ?)", m.first_name, m.last_name),
      checker_name: fragment("CONCAT(?, ' ', ?)", c.first_name, c.last_name)
    })
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp handle_integrator_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        integrator_isearch_filter(query, Utils.sanitize_term(value))

      {"name", value}, query when byte_size(value) > 0 ->
        where(query, [s], fragment("lower(?) LIKE lower(?)", s.name, ^Utils.sanitize_term(value)))

      {"status", value}, query when byte_size(value) > 0 ->
        where(query, [s], fragment("lower(?) LIKE lower(?)", s.status, ^Utils.sanitize_term(value)))

      {"integrator_id", value}, query when byte_size(value) > 0 ->
        where(query, [s], fragment("lower(?) LIKE lower(?)", s.integrator_id, ^Utils.sanitize_term(value)))

      {"contact_email", value}, query when byte_size(value) > 0 ->
        where(query, [s], fragment("lower(?) LIKE lower(?)", s.contact_email, ^Utils.sanitize_term(value)))

      {"ip_address", value}, query when byte_size(value) > 0 ->
        where(query, [s], fragment("lower(?) LIKE lower(?)", s.ip_address, ^Utils.sanitize_term(value)))

      {"port", value}, query when byte_size(value) > 0 ->
        where(query, [s], s.port == ^String.to_integer(value))

      {"from", value}, query when byte_size(value) > 0 ->
        where(query, [s], fragment("CAST(? AS DATE) >= ?", s.inserted_at, ^value))

      {"to", value}, query when byte_size(value) > 0 ->
        where(query, [s], fragment("CAST(? AS DATE) <= ?", s.inserted_at, ^value))

      {_, _}, query ->
        # Not a where parameter
        query
    end)
  end

  defp integrator_isearch_filter(query, search_term) do
    where(
      query,
      [s, m, c],
      fragment("lower(?) LIKE lower(?)", s.name, ^search_term) or
      fragment("lower(?) LIKE lower(?)", s.integrator_id, ^search_term) or
      fragment("lower(?) LIKE lower(?)", s.contact_email, ^search_term) or
      fragment("lower(?) LIKE lower(?)", s.status, ^search_term) or
      fragment("lower(?) LIKE lower(?)", s.endpoint, ^search_term) or
      fragment("lower(?) LIKE lower(?)", s.ip_address, ^search_term)
    )
  end

  defp compose_integrator_select(query) do
    query
    |> select(
      [s, m, c],
      map(s, [
        :id,
        :name,
        :status,
        :integrator_id,
        :callback_url,
        :endpoint,
        :auth_token,
        :attempt_count,
        :contact_email,
        :ip_address,
        :port,
        :maker_id,
        :checker_id,
        :inserted_at,
        :updated_at
      ])
    )
  end

  def list_integrators do
    ApiIntegrator
    |> preload([:maker, :checker])
    |> Repo.all()
  end

  def get_integrator!(id) do
    ApiIntegrator
    |> preload([:maker, :checker])
    |> Repo.get!(id)
  end

  def get_integrator_by_id(id) do
    ApiIntegrator
    |> preload([:maker, :checker])
    |> Repo.get_by(id: id)
  end

  def get_integrator_by_integrator_id(integrator_id) do
    ApiIntegrator
    |> preload([:maker, :checker])
    |> Repo.get_by(integrator_id: integrator_id)
  end

  def create_integrator(attrs \\ %{}) do
    %ApiIntegrator{}
    |> ApiIntegrator.changeset(attrs)
    |> Repo.insert()
  end

  def update_integrator(%ApiIntegrator{} = integrator, attrs) do
    integrator
    |> ApiIntegrator.changeset(attrs)
    |> Repo.update()
  end

  def delete_integrator(%ApiIntegrator{} = integrator) do
    Repo.delete(integrator)
  end

  def change_integrator(%ApiIntegrator{} = integrator, attrs \\ %{}) do
    ApiIntegrator.changeset(integrator, attrs)
  end

  def get_integrator_by_token(token) do
    ApiIntegrator
    |> Repo.get_by(auth_token: token)
  end

  def verify_integrator_password(%ApiIntegrator{} = integrator, password) do
    ApiIntegrator.valid_password?(integrator, password)
  end

  def increment_attempt_count(%ApiIntegrator{} = integrator) do
    {count, _} =
      from(s in ApiIntegrator, where: s.id == ^integrator.id)
      |> Repo.update_all(inc: [attempt_count: 1])

    count > 0
  end

  def reset_attempt_count(%ApiIntegrator{} = integrator) do
    {count, _} =
      from(s in ApiIntegrator, where: s.id == ^integrator.id)
      |> Repo.update_all(set: [attempt_count: 0])

    count > 0
  end

  def generate_new_password(%ApiIntegrator{} = integrator) do
    # Generate a random password with specific requirements
    password = :crypto.strong_rand_bytes(12)
    |> Base.encode64()
    |> binary_part(0, 12)
    |> ensure_password_requirements()

    # Update the integrator with the new password
    integrator
    |> ApiIntegrator.update_changeset(%{password: password}, hash_password: true)
    |> Repo.update()
    |> case do
      {:ok, updated_integrator} -> {:ok, password, updated_integrator}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # Ensure password meets requirements (at least one uppercase, one lowercase)
  defp ensure_password_requirements(password) do
    password = String.replace(password, ~r/[^A-Za-z0-9]/, "")
    password = if String.match?(password, ~r/[A-Z]/), do: password, else: password <> "A"
    password = if String.match?(password, ~r/[a-z]/), do: password, else: password <> "a"
    password = if String.match?(password, ~r/[0-9]/), do: password, else: password <> "1"
    String.slice(password, 0, 12)
  end
end
