defmodule FinincialAgentWeb.PermissionGroupsLive.FormComponent do
  use FinincialAgentWeb, :live_component

  alias FinincialAgent.Roles

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="permission_groups-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:group]} type="text" label="Group" />
        <.input field={@form[:section]} type="text" label="Section" />
        <:actions>
          <.button phx-disable-with="Saving..." class="bg-green-600">Save group</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{permission_group: permission_groups} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Roles.change_permission_groups(permission_groups))
     end)}
  end

  @impl true
  def handle_event("validate", %{"permission_groups" => permission_groups_params}, socket) do
    changeset =
      Roles.change_permission_groups(socket.assigns.permission_group, permission_groups_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"permission_groups" => permission_groups_params}, socket) do
    save_permission_groups(socket, socket.assigns.action, permission_groups_params)
  end

  defp save_permission_groups(socket, :edit, permission_groups_params) do
    case Roles.update_permission_groups(
           socket.assigns.permission_group,
           permission_groups_params
         ) do
      {:ok, _permission_groups} ->
        # notify_parent({:saved, permission_groups})

        {:noreply,
         socket
         |> put_flash(:info, "Permission groups updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_permission_groups(socket, :new, permission_groups_params) do
    case Roles.create_permission_groups(Map.put(permission_groups_params, "status", "ACTIVE")) do
      {:ok, _permission_groups} ->
        # notify_parent({:list_permission_group, permission_groups})

        {:noreply,
         socket
         |> put_flash(:info, "Permission groups created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # defp notify_parent(msg), do: send(self(), msg)
end
