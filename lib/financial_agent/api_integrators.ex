defmodule FinancialAgent.ApiIntegrators do
  import Ecto.Query, warn: false
  @pagination [page_size: 10]

  alias FinancialAgent.Repo
  alias FinancialAgent.Workers.Util.Utils
  alias FinancialAgent.Settings.ApiIntegrator

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
      fragment("lower(?) LIKE lower(?)", s.endpoint, ^search_term)
    )
  end

  defp compose_integrator_select(query) do
    query
    |> select(
      [s, m, c],
      map(s, [
        :id,
        :name,
        :integrator_id,
        :callback_url,
        :endpoint,
        :auth_token,
        :attempt_count,
        :contact_email,
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
