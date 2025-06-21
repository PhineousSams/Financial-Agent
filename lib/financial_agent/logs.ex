defmodule FinincialTool.Logs do
  import Ecto.Query, warn: false
  @pagination [page_size: 10]

  alias FinincialTool.Repo
  alias FinincialTool.Logs.UserLogs
  alias FinincialTool.Logs.SessionLogs
  alias FinincialTool.Logs.AuditLogs
  alias FinincialTool.Accounts.User
  alias FinincialTool.Logs.ApiLogs
  alias FinincialTool.Logs.ServiceLogs
  alias FinincialTool.Workers.Util.Utils

  def get_user_logs(search_params) do
    UserLogs
    |> join(:left, [l], u in "tbl_user", on: l.user_id == u.id)
    |> order_by(desc: :inserted_at)
    |> select([l, u], %{
      first_name: u.first_name,
      last_name: u.last_name,
      activity: l.activity,
      date: l.inserted_at,
      user_id: l.user_id
    })
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  def list_tbl_user_logs do
    Repo.all(UserLogs)
  end

  def get_user_logs!(id), do: Repo.get!(UserLogs, id)

  def create_user_logs(attrs \\ %{}) do
    %UserLogs{}
    |> UserLogs.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_logs(%UserLogs{} = user_logs, attrs) do
    user_logs
    |> UserLogs.changeset(attrs)
    |> Repo.update()
  end

  def delete_user_logs(%UserLogs{} = user_logs) do
    Repo.delete(user_logs)
  end

  def change_user_logs(%UserLogs{} = user_logs, attrs \\ %{}) do
    UserLogs.changeset(user_logs, attrs)
  end

  # ================================ SessionLogs =============================

  def system_log_session(session, description, action, attrs, service, user_id) do
    SessionLogs.changeset(
      %SessionLogs{},
      %{
        description: description,
        action: action,
        attrs: Poison.encode!(attrs),
        service: service,
        session_id: session["live_socket_id"],
        ip_address: session["remote_ip"],
        device_uuid: session["user_agent"],
        full_browser_name: session["browser_info"]["full_browser_name"],
        browser_details: session["browser_info"]["browser_details"],
        system_platform_name: session["browser_info"]["system_platform_name"],
        device_type: to_string(session["browser_info"]["device_type"]),
        known_browser: session["browser_info"]["known_browser"],
        user_id: user_id
      }
    )
    |> Repo.insert!()
  end

  def session_logs(conn, session_id, portal, description, user_id, status \\ false) do
    SessionLogs.changeset(%SessionLogs{}, %{
      session_id: session_id,
      portal: portal,
      description: description,
      device_uuid: device_uuid(conn),
      full_browser_name: Browser.full_browser_name(conn),
      user_id: user_id,
      browser_details: Browser.full_display(conn),
      system_platform_name: Browser.full_platform_name(conn),
      device_type: to_string(Browser.device_type(conn)),
      known_browser: Browser.known?(conn),
      status: status,
      ip_address: ip_address(conn)
    })
    |> Repo.insert!()
  end

  def find_and_update_session_id_log_out(
        session_id,
        user_id,
        message \\ "Session Force Close Successfully"
      ) do
    SessionLogs
    |> where([a], a.session_id == ^session_id and a.user_id == ^user_id)
    |> Repo.all()
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {session, idx}, multi ->
      Ecto.Multi.update(
        multi,
        {:session, idx},
        SessionLogs.changeset(session, %{
          status: false,
          description: message,
          log_out_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
        })
      )
    end)
    |> Repo.transaction()
  end

  def system_log_session_live_multi(
        multi,
        %{assigns: _assigns},
        description,
        action,
        attrs,
        service,
        _user_id \\ 1
      ) do
    data = FinincialTool.Workers.Util.Cache.get(:assigns)

    Ecto.Multi.insert(
      multi,
      :system_logs,
      SessionLogs.changeset(
        %SessionLogs{},
        %{
          description: description,
          action: action,
          attrs: Poison.encode!(attrs),
          service: service,
          session_id: data.live_socket_identifier,
          ip_address: data.remote_ip,
          device_uuid: data.user_agent,
          full_browser_name: data.browser_info["full_browser_name"],
          browser_details: data.browser_info["browser_details"],
          system_platform_name: data.browser_info["system_platform_name"],
          device_type: to_string(data.browser_info["device_type"]),
          known_browser: data.browser_info["known_browser"],
          user_id: data.user.id
        }
      )
    )
  end

  def log_session(%{assigns: _assigns}, description, action, attrs, service) do
    data = FinincialTool.Workers.Util.Cache.get(:assigns)

    changeset =
      SessionLogs.changeset(
        %SessionLogs{},
        %{
          description: description,
          action: action,
          attrs: Poison.encode!(attrs),
          service: service,
          session_id: data.live_socket_identifier,
          ip_address: data.remote_ip,
          device_uuid: data.user_agent,
          full_browser_name: data.browser_info["full_browser_name"],
          browser_details: data.browser_info["browser_details"],
          system_platform_name: data.browser_info["system_platform_name"],
          device_type: to_string(data.browser_info["device_type"]),
          known_browser: data.browser_info["known_browser"],
          user_id: data.user.id
        }
      )

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:session_logs, changeset)
  end

  def system_log_live(%{assigns: assigns}, narration, action, attrs, service, user_id) do
    SessionLogs.changeset(
      %SessionLogs{},
      %{
        narration: narration,
        action: action,
        attrs: Poison.encode!(attrs),
        service: service,
        session_id: assigns.live_socket_identifier,
        ip_address: assigns.remote_ip,
        device_uuid: assigns.user_agent,
        full_browser_name: assigns.browser_info["full_browser_name"],
        browser_details: assigns.browser_info["browser_details"],
        system_platform_name: assigns.browser_info["system_platform_name"],
        device_type: to_string(assigns.browser_info["device_type"]),
        known_browser: assigns.browser_info["known_browser"],
        user_id: user_id
      }
    )
    |> Repo.insert!()
  end

  def insert_live_log(%{assigns: assigns}, narration, action, attrs, service, user_id) do
    SessionLogs.changeset(
      %SessionLogs{},
      %{
        description: narration,
        action: action,
        attrs: Poison.encode!(attrs),
        service: service,
        session_id: assigns.live_socket_identifier,
        ip_address: assigns.remote_ip,
        device_uuid: assigns.user_agent,
        full_browser_name: assigns.browser_info["full_browser_name"],
        browser_details: assigns.browser_info["browser_details"],
        system_platform_name: assigns.browser_info["system_platform_name"],
        device_type: to_string(assigns.browser_info["device_type"]),
        known_browser: assigns.browser_info["known_browser"],
        user_id: user_id
      }
    )
    |> Repo.insert!()
  end

  def ip_address(conn, _live \\ false) do
    forwarded_for = List.first(Plug.Conn.get_req_header(conn, "x-forwarded-for"))

    if forwarded_for do
      String.split(forwarded_for, ",")
      |> Enum.map(&String.trim/1)
      |> List.first()
    else
      to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end

  def device_uuid(conn) do
    Plug.Conn.get_req_header(conn, "user-agent")
    |> List.first()
  end

  def list_tbl_user_session do
    Repo.all(SessionLogs)
  end

  def get_user_session!(id), do: Repo.get!(SessionLogs, id)

  def create_user_session(attrs \\ %{}) do
    %SessionLogs{}
    |> SessionLogs.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_session(%SessionLogs{} = user_session, attrs) do
    user_session
    |> SessionLogs.changeset(attrs)
    |> Repo.update()
  end

  def delete_user_session(%SessionLogs{} = user_session) do
    Repo.delete(user_session)
  end

  def change_user_session(%SessionLogs{} = user_session, attrs \\ %{}) do
    SessionLogs.changeset(user_session, attrs)
  end

  def session_logs(search_params) do
    SessionLogs
    |> join(:left, [l], u in "tbl_user", on: l.user_id == u.id)
    |> order_by(desc: :inserted_at)
    |> by_user?(search_params)
    |> select([l, u], %{
      first_name: u.first_name,
      last_name: u.last_name,
      username: u.username,
      session_id: l.session_id,
      status: l.status,
      portal: l.portal,
      description: l.description,
      device_uuid: l.device_uuid,
      ip_address: l.ip_address,
      full_browser_name: l.full_browser_name,
      browser_details: l.browser_details,
      user_id: l.user_id,
      device_type: l.device_type,
      known_browse: l.known_browser,
      inserted_at: l.inserted_at,
      system_platform_name: l.system_platform_name
    })
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  def user_session_logs(search_params, session_id) do
    SessionLogs
    |> join(:left, [l], u in "tbl_user", on: l.user_id == u.id)
    |> where([l, u], l.session_id == ^session_id)
    |> order_by(desc: :inserted_at)
    |> by_user?(search_params)
    |> select([l, u], %{
      first_name: u.first_name,
      last_name: u.last_name,
      username: u.username,
      session_id: l.session_id,
      status: l.status,
      portal: l.portal,
      description: l.description,
      device_uuid: l.device_uuid,
      ip_address: l.ip_address,
      full_browser_name: l.full_browser_name,
      browser_details: l.browser_details,
      user_id: l.user_id,
      device_type: l.device_type,
      known_browse: l.known_browser,
      inserted_at: l.inserted_at,
      system_platform_name: l.system_platform_name
    })
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp by_user?(queryable, %{"user_id" => user_id}) do
    queryable
    |> where([l, u], l.user_id == ^user_id)
  end

  defp by_user?(queryable, _), do: queryable

  # =============== GENERAL LOGS ========================
  def log_action(conn, map, pre_data \\ %{}, post_data \\ %{}, metadata \\ %{}) do
    user_id = conn.assigns[:current_user].id
    description = "#{map.action} performed on #{map.resource_type}"

    user_log = %{
      activity: "#{map.action} #{map.resource_type}",
      user_id: user_id,
      pre_data: pre_data,
      post_data: post_data,
      action: map.action
    }

    audit_params = %{
      action: map.action,
      description: map.description,
      resource_type: map.resource_type,
      resource_id: map.resource_id,
      pre_data: pre_data,
      post_data: post_data,
      metadata: metadata,
      user_id: user_id
    }

    session_logs = session_params(conn, description, map.portal, user_id, true)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user_log, UserLogs.changeset(%UserLogs{}, user_log))
    |> Ecto.Multi.insert(:audit_log, AuditLogs.changeset(%AuditLogs{}, audit_params))
    |> Ecto.Multi.insert(:session_log, SessionLogs.changeset(%SessionLogs{}, session_logs))
  end

  def session_params(%{assigns: assigns} = conn, description, portal, user_id, status) do
    session_id = assigns.live_socket_identifier

    case get_session_log(user_id, session_id) do
      nil ->
        %{
          session_id: session_id,
          portal: portal,
          description: description,
          device_uuid: device_uuid(conn),
          full_browser_name: Browser.full_browser_name(conn),
          user_id: user_id,
          browser_details: Browser.full_display(conn),
          system_platform_name: Browser.full_platform_name(conn),
          device_type: to_string(Browser.device_type(conn)),
          known_browser: Browser.known?(conn),
          status: status,
          ip_address: ip_address(conn)
        }

      session ->
        %{
          session_id: session_id,
          portal: session.portal,
          description: description,
          device_uuid: session.device_uuid,
          full_browser_name: session.full_browser_name,
          user_id: user_id,
          browser_details: session.browser_details,
          system_platform_name: session.system_platform_name,
          device_type: session.device_type,
          known_browser: session.known_browser,
          status: status,
          ip_address: session.ip_address
        }
    end
  end

  defp get_session_log(user_id, session_id) do
    SessionLogs
    |> where([a], a.session_id == ^session_id and a.user_id == ^user_id)
    |> limit(1)
    |> Repo.one()
  end

  def get_audit_logs(search_params) do
    AuditLogs
    |> join(:left, [l], u in "tbl_user", on: l.user_id == u.id)
    |> order_by(desc: :created_at)
    |> select([l, u], %{
      first_name: u.first_name,
      last_name: u.last_name,
      action: l.action,
      description: l.description,
      resource_type: l.resource_type,
      resource_id: l.resource_id,
      pre_data: l.pre_data,
      post_data: l.post_data,
      metadata: l.metadata,
      user_id: l.user_id,
      created_at: l.created_at
    })
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end



  # =========== ApiLogs ===========
  def get_api_logs(search_params) do
    ApiLogs
    |> handle_api_logs_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_api_logs_select()
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp handle_api_logs_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        api_logs_isearch_filter(query, Utils.sanitize_term(value))

      {"ref_id", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.ref_id, ^Utils.sanitize_term(value)))

      {"api_key", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.api_key, ^Utils.sanitize_term(value)))

      {"endpoint", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.endpoint, ^Utils.sanitize_term(value)))

      {"request_method", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.request_method, ^Utils.sanitize_term(value)))

      {"request_path", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.request_path, ^Utils.sanitize_term(value)))

      {"response_status", value}, query when byte_size(value) > 0 ->
        where(query, [l], l.response_status == ^String.to_integer(value))

      {"ip_address", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.ip_address, ^Utils.sanitize_term(value)))

      {"from", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("CAST(? AS DATE) >= ?", l.inserted_at, ^value))

      {"to", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("CAST(? AS DATE) <= ?", l.inserted_at, ^value))

      {_, _}, query ->
        # Not a where parameter
        query
    end)
  end

  defp api_logs_isearch_filter(query, search_term) do
    where(
      query,
      [l],
      fragment("lower(?) LIKE lower(?)", l.ref_id, ^search_term) or
      fragment("lower(?) LIKE lower(?)", l.api_key, ^search_term) or
      fragment("lower(?) LIKE lower(?)", l.endpoint, ^search_term) or
      fragment("lower(?) LIKE lower(?)", l.request_method, ^search_term) or
      fragment("lower(?) LIKE lower(?)", l.request_path, ^search_term) or
      fragment("lower(?) LIKE lower(?)", l.ip_address, ^search_term)
    )
  end

  defp compose_api_logs_select(query) do
    query
    |> select(
      [l],
      map(l, [
        :id,
        :ref_id,
        :api_key,
        :endpoint,
        :request_method,
        :request_path,
        :request_params,
        :response_status,
        :response_body,
        :processing_time_ms,
        :ip_address,
        :user_agent,
        :error_details,
        :service_type,
        :service_id,
        :inserted_at,
        :updated_at
      ])
    )
  end

  def list_api_logs do
    Repo.all(ApiLogs)
  end

  def get_api_logs!(id), do: Repo.get!(ApiLogs, id)

  def create_api_logs(attrs \\ %{}) do
    %ApiLogs{}
    |> ApiLogs.changeset(attrs)
    |> Repo.insert()
  end

  def update_api_logs(%ApiLogs{} = api_logs, attrs) do
    api_logs
    |> ApiLogs.changeset(attrs)
    |> Repo.update()
  end

  def delete_api_logs(%ApiLogs{} = api_logs) do
    Repo.delete(api_logs)
  end

  def change_api_logs(%ApiLogs{} = api_logs, attrs \\ %{}) do
    ApiLogs.changeset(api_logs, attrs)
  end


  # =========== ServiceLogs ===========
  def get_service_logs(search_params) do
    ServiceLogs
    |> handle_service_logs_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_service_logs_select()
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp handle_service_logs_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        service_logs_isearch_filter(query, Utils.sanitize_term(value))

      {"service_type", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.service_type, ^Utils.sanitize_term(value)))

      {"request_type", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.request_type, ^Utils.sanitize_term(value)))

      {"request_id", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.request_id, ^Utils.sanitize_term(value)))

      {"request_method", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.request_method, ^Utils.sanitize_term(value)))

      {"request_url", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.request_url, ^Utils.sanitize_term(value)))

      {"response_code", value}, query when byte_size(value) > 0 ->
        where(query, [l], l.response_code == ^String.to_integer(value))

      {"status", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("lower(?) LIKE lower(?)", l.status, ^Utils.sanitize_term(value)))

      {"from", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("CAST(? AS DATE) >= ?", l.inserted_at, ^value))

      {"to", value}, query when byte_size(value) > 0 ->
        where(query, [l], fragment("CAST(? AS DATE) <= ?", l.inserted_at, ^value))

      {_, _}, query ->
        # Not a where parameter
        query
    end)
  end

  defp service_logs_isearch_filter(query, search_term) do
    where(
      query,
      [l],
      fragment("lower(?) LIKE lower(?)", l.service_type, ^search_term) or
      fragment("lower(?) LIKE lower(?)", l.request_type, ^search_term) or
      fragment("lower(?) LIKE lower(?)", l.request_id, ^search_term) or
      fragment("lower(?) LIKE lower(?)", l.request_method, ^search_term) or
      fragment("lower(?) LIKE lower(?)", l.request_url, ^search_term) or
      fragment("lower(?) LIKE lower(?)", l.status, ^search_term)
    )
  end

  defp compose_service_logs_select(query) do
    query
    |> select(
      [l],
      map(l, [
        :id,
        :request_type,
        :request_id,
        :request_url,
        :request_method,
        :request_headers,
        :request_body,
        :response_code,
        :response_body,
        :duration_ms,
        :status,
        :error_message,
        :metadata,
        :service_type,
        :service_id,
        :inserted_at,
        :updated_at
      ])
    )
  end

  def list_service_logs do
    Repo.all(ServiceLogs)
  end

  def get_service_log!(id), do: Repo.get!(ServiceLogs, id)

  def get_service_logs!(id), do: Repo.get!(ServiceLogs, id)

  def create_service_logs(attrs \\ %{}) do
    %ServiceLogs{}
    |> ServiceLogs.changeset(attrs)
    |> Repo.insert()
  end

  def update_service_logs(%ServiceLogs{} = service_logs, attrs) do
    service_logs
    |> ServiceLogs.changeset(attrs)
    |> Repo.update()
  end

  def delete_service_logs(%ServiceLogs{} = service_logs) do
    Repo.delete(service_logs)
  end

  def change_service_logs(%ServiceLogs{} = service_logs, attrs \\ %{}) do
    ServiceLogs.changeset(service_logs, attrs)
  end
end
