defmodule FinincialAgentWeb.NotificationLive.ThreeInfoModalLive do
  @moduledoc false
  use FinincialAgentWeb, :live_component

  def render(assigns) do
    ~H"""
    <div
      id={"modal-#{@id}"}
      class="fixed inset-0 flex items-center justify-center bg-gray-900 bg-opacity-50 z-50"
    >
      <div class="bg-white rounded-lg shadow-lg max-w-sm mx-auto" style="max-width: 500px">
        <!-- Modal Header -->
        <div class="bg-gray-800 text-white py-3 px-4 flex justify-center items-center rounded-t-lg">
          <h5 class="text-lg font-semibold" id="exampleModalLabel"><%= @title %></h5>
        </div>
        <!-- Modal Body -->
        <div class="p-4 text-center">
          <h3 class="text-lg font-medium"><%= @body %></h3>
          <!-- Modal Footer -->
          <div class="flex justify-around mt-4">
            <form phx-target={@myself} phx-submit="left_button">
              <button
                type="submit"
                class="bg-red-500 text-white px-4 py-2 rounded-lg border border-red-600 hover:bg-red-600"
              >
                <%= @left_button %>
              </button>
            </form>

            <form phx-target={@myself} phx-submit="middle_button">
              <button
                type="submit"
                class="bg-gray-500 text-white px-4 py-2 rounded-lg border border-gray-600 hover:bg-gray-600"
              >
                <%= @middle_button %>
              </button>
            </form>

            <form phx-target={@myself} phx-submit="right_button">
              <button
                type="submit"
                class="bg-blue-600 text-white px-4 py-2 rounded-lg border border-green-600 hover:bg-green-600"
              >
                <%= @right_button %>
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def handle_event(target, params, socket), do: handle_event_switch(target, params, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "right_button" -> right_button_click(params, socket)
      "left_button" -> left_button_click(params, socket)
      "middle_button" -> middle_button_click(params, socket)
    end
  end

  # Fired when user clicks right button on modal
  defp right_button_click(
         _params,
         %{
           assigns: %{
             right_button_action: action,
             right_button_param: param
           }
         } = socket
       ) do
    send(
      self(),
      {__MODULE__, :button_clicked, %{action: action, param: param}}
    )

    {:noreply, socket}
  end

  defp middle_button_click(
         _params,
         %{
           assigns: %{
             middle_button_action: action,
             right_button_param: param
           }
         } = socket
       ) do
    send(
      self(),
      {__MODULE__, :button_clicked, %{action: action, param: param}}
    )

    {:noreply, socket}
  end

  defp left_button_click(
         _params,
         %{
           assigns: %{
             left_button_action: action,
             right_button_param: param
           }
         } = socket
       ) do
    send(self(), {__MODULE__, :button_clicked, %{action: action, param: param}})
    {:noreply, socket}
  end
end
