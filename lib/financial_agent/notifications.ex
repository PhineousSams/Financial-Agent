defmodule FinincialTool.Notifications do
  import Ecto.Query, warn: false
  @pagination [page_size: 10]

  alias FinincialTool.Repo
  alias FinincialTool.Notifications.Sms
  alias FinincialTool.Notifications.Email
  alias FinincialTool.Workers.Util.Utils
  alias FinincialTool.Notifications.Alerts

  # alias FinincialTool.Notifications.Announcement

  def list_tbl_email_logs do
    Repo.all(Email)
  end

  def get_email!(id), do: Repo.get!(Email, id)

  def create_email(attrs \\ %{}) do
    %Email{}
    |> Email.changeset(attrs)
    |> Repo.insert()
  end

  def update_email(%Email{} = email, attrs) do
    email
    |> Email.changeset(attrs)
    |> Repo.update()
  end

  def delete_email(%Email{} = email) do
    Repo.delete(email)
  end

  def change_email(%Email{} = email, attrs \\ %{}) do
    Email.changeset(email, attrs)
  end

  def get_all_emails(search_params) do
    Email
    |> handle_mail_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_mail_select()
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp handle_mail_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        isearch_filter(query, Utils.sanitize_term(value))

      {"address", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.recipient_email, ^Utils.sanitize_term(value))
        )

      {"status", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.status, ^Utils.sanitize_term(value))
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

  defp isearch_filter(query, search_term) do
    where(
      query,
      [a],
      fragment("lower(?) LIKE lower(?)", a.recipient_email, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.status, ^search_term)
    )
  end

  defp compose_mail_select(query) do
    query
    |> select(
      [t],
      map(t, [
        :id,
        :subject,
        :sender_email,
        :sender_name,
        :mail_body,
        :recipient_email,
        :status,
        :attempts,
        :inserted_at
      ])
    )
  end

  # ================================ SMS ========================================

  def sms_settings do
    Repo.all(Sms)
  end

  def get_sms!(id), do: Repo.get!(Sms, id)

  def create_sms(attrs \\ %{}) do
    %Sms{}
    |> Sms.changeset(attrs)
    |> Repo.insert()
  end

  def update_sms(%Sms{} = sms, attrs) do
    sms
    |> Sms.changeset(attrs)
    |> Repo.update()
  end

  def delete_sms(%Sms{} = sms) do
    Repo.delete(sms)
  end

  def change_sms(%Sms{} = sms, attrs \\ %{}) do
    Sms.changeset(sms, attrs)
  end

  def get_sms_logs(search_params) do
    Sms
    |> handle_sms_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_sms_select()
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp handle_sms_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        sms_isearch_filter(query, Utils.sanitize_term(value))

      # {"batch_reference", value}, query when byte_size(value) > 0 ->
      #   where(query, [a], fragment("lower(?) LIKE lower(?)", a.ref, ^Utils.sanitize_term(value)))

      {"mobile", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.mobile, ^Utils.sanitize_term(value))
        )

      {"sms_text", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("lower(?) LIKE lower(?)", a.sms, ^Utils.sanitize_term(value)))

      {"status", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.status, ^Utils.sanitize_term(value))
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

  defp sms_isearch_filter(query, search_term) do
    where(
      query,
      [a],
      # fragment("lower(?) LIKE lower(?)", a.ref, ^search_term) or
      fragment("lower(?) LIKE lower(?)", a.mobile, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.sms, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.status, ^search_term)
    )
  end

  defp compose_sms_select(query) do
    query
    |> select(
      [t],
      map(t, [
        :id,
        :type,
        :mobile,
        :sms,
        :status,
        :msg_count,
        :date_sent,
        :inserted_at
      ])
    )
  end

  #  ============================== ANNOUNCEMENT =============================

  def list_tbl_alert do
    Repo.all(Alerts)
  end

  def list_client_alerts do
    Alerts
     |> where([a], a.status == "ACTIVE" and a.alert_type == "CLIENT")
     |> order_by(desc: :inserted_at)
     |> Repo.all()
  end

  def list_staff_alerts do
    Alerts
     |> where([a], a.status == "ACTIVE" and a.alert_type == "STAFF")
     |> order_by(desc: :inserted_at)
     |> Repo.all()
  end


  def get_alerts!(id), do: Repo.get!(Alerts, id)

  def create_alerts(attrs \\ %{}) do
    %Alerts{}
    |> Alerts.changeset(attrs)
    |> Repo.insert()
  end



  def count_staff_alerts do
    Alerts
    |> where([a], a.alert_type == "STAFF" and a.status == "ACTIVE")
    |> Repo.aggregate(:count, :id)
  end

  def get_newest_staff_notifications do
    Alerts
    |> where([a], a.alert_type == "STAFF" and a.status == "ACTIVE")
    |> order_by(desc: :inserted_at)
    |> limit(3)
    |> Repo.all()
  end


  def count_client_alerts do
    Alerts
    |> where([a], a.alert_type == "CLIENT" and a.status == "ACTIVE")
    |> Repo.aggregate(:count, :id)
  end


  def get_newest_client_notifications do
    Alerts
    |> where([a], a.alert_type == "CLIENT" and a.status == "ACTIVE")
    |> order_by(desc: :inserted_at)
    |> limit(3)
    |> Repo.all()
  end




  @doc """
  Updates a alerts.

  ## Examples

      iex> update_alerts(alerts, %{field: new_value})
      {:ok, %Alerts{}}

      iex> update_alerts(alerts, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_alerts(%Alerts{} = alerts, attrs) do
    alerts
    |> Alerts.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a alerts.

  ## Examples

      iex> delete_alerts(alerts)
      {:ok, %Alerts{}}

      iex> delete_alerts(alerts)
      {:error, %Ecto.Changeset{}}

  """
  def delete_alerts(%Alerts{} = alerts) do
    Repo.delete(alerts)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking alerts changes.

  ## Examples

      iex> change_alerts(alerts)
      %Ecto.Changeset{data: %Alerts{}}

  """
  def change_alerts(%Alerts{} = alerts, attrs \\ %{}) do
    Alerts.changeset(alerts, attrs)
  end

  def list_system_alerts(search_params) do
    Alerts
    |> where([a], a.status != "DELETED")
    |> handle_system_alert_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_system_alert_select()
    |> select_merge([a, _u], %{
      approver: fragment("select first_name || last_name from tbl_user where id = ?", a.approved_by_id),
      creator: fragment("select first_name || last_name from tbl_user where id = ?", a.created_by_id)
    })
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp compose_system_alert_select(query) do
    query
    |> select(
      [com],
      map(com, [
        :id,
        :alert_type,
        :description,
        :message,
        :status,
        :created_by_id,
        :approved_by_id
      ])
    )
  end

  defp handle_system_alert_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        system_alert_isearch_filter(query, Utils.sanitize_term(value))

      {"alert_type", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [com],
          fragment("lower(?) LIKE lower(?)", com.alert_type, ^Utils.sanitize_term(value))
        )

      {"inserted_at", value}, query when byte_size(value) > 0 ->
        where(query, [com], fragment("CAST(? AS DATE) >= ?", com.inserted_at, ^value))

      {"updated_at", value}, query when byte_size(value) > 0 ->
        where(query, [com], fragment("CAST(? AS DATE) <= ?", com.updated_at, ^value))

      {_, _}, query ->
        # Not a where parameter
        query
    end)
  end

  defp system_alert_isearch_filter(query, search_term) do
    where(
      query,
      [com],
      fragment("lower(?) LIKE lower(?)", com.alert_type, ^search_term) or
        fragment("lower(?) LIKE lower(?)", com.description, ^search_term) or
        fragment("lower(?) LIKE lower(?)", com.message, ^search_term) or
        fragment("lower(?) LIKE lower(?)", com.status, ^search_term) or
        fragment("lower(?) LIKE lower(?)", com.created_by_id, ^search_term) or
        fragment("lower(?) LIKE lower(?)", com.approved_by_id, ^search_term)
    )
  end
end
