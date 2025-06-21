defmodule FinincialToolWeb.ApiIntegratorsLive.FormComponent do
  use FinincialToolWeb, :live_component

  alias FinincialTool.Repo
  alias FinincialTool.Logs
  alias FinincialTool.Settings
  alias FinincialTool.Workers.Util.Utils
  alias FinincialTool.Settings.ApiIntegrator
  alias FinincialTool.Workers.Util.Cache


  @impl true
  def update(%{integrator: integrator} = assigns, socket) do
    changeset = Settings.change_integrator(integrator)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event(target, params, socket), do: handle_event_switch(target, params, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "validate" -> validate_integrator(params["api_integrator"], socket)
      "save" -> save_integrator(socket, socket.assigns.action, params["api_integrator"])
    end
  end

  defp validate_integrator(integrator_params, socket) do
    changeset =
      socket.assigns.integrator
      |> Settings.change_integrator(integrator_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  defp save_integrator(%{assigns: assigns} = socket, type, params) do
    params = Utils.to_atomic_map(params)

    case handle_integrator(socket, params, type) do
      {:ok, message} ->
        {:noreply,
          socket
          |> put_flash(:info, message)
          |> push_navigate(to: socket.assigns.return_to, replace: true)
        }

      {:error, reason} ->

        {:noreply,
          socket
          |> put_flash(:error, reason)
          |> push_navigate(to: socket.assigns.return_to, replace: true)
        }
    end
  end

  defp handle_integrator(%{assigns: assigns} = socket, integrator, :new) do
    Cache.put(assigns, :assigns)
    integrator = Map.merge(integrator, %{
      maker_id: assigns.user.id,
      checker_id: assigns.user.id,
      status: "ACTIVE",
      integrator_id: Ecto.UUID.generate()
    })

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:integrator, ApiIntegrator.changeset(%ApiIntegrator{}, integrator))
    |> Ecto.Multi.merge(fn %{integrator: integrator} ->
      Logs.log_session(
        socket,
        "Create Integrator [#{integrator.name}]",
        "CREATE",
        integrator,
        "Integration Management"
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        {:ok, "API Integrator created successfully"}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {:error, reason}
    end
  end

  defp handle_integrator(%{assigns: assigns} = socket, integrator, :edit) do
    Cache.put(assigns, :assigns)
    integrator = Map.merge(integrator, %{checker_id: assigns.user.id})

    Ecto.Multi.new()
    |> Ecto.Multi.update(:integrator, ApiIntegrator.changeset(assigns.integrator, integrator))
    |> Ecto.Multi.merge(fn %{integrator: integrator} ->
      Logs.log_session(
        socket,
        "Create Integrator [#{integrator.name}]",
        "EDIT",
        integrator,
        "Integration Management"
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        {:ok, "API Integrator updated successfully"}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {:error, reason}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :changeset, to_form(changeset))
  end
end
