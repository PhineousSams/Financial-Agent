defmodule FinincialToolWeb.ChatLive.Index do
  use FinincialToolWeb, :live_view

  alias FinincialTool.AI
  alias FinincialTool.AI.Agent
  alias FinincialTool.Auth

  @impl true
  def mount(_params, session, %{assigns: %{user: user} = assigns} = socket) do
    if user do
      conversations = AI.list_conversations(user.id)

      socket =
        socket
        |> assign(:conversations, conversations)
        |> assign(:current_conversation, nil)
        |> assign(:messages, [])
        |> assign(:message_input, "")
        |> assign(:loading, false)
        |> assign(:connected_services, get_connected_services(user.id))

      {:ok, socket}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_params(%{"conversation_id" => conversation_id}, _uri, socket) do
    user = socket.assigns.user

    case AI.get_user_conversation(user.id, String.to_integer(conversation_id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Conversation not found")}

      conversation ->
        messages = AI.list_messages(conversation.id)

        socket =
          socket
          |> assign(:current_conversation, conversation)
          |> assign(:messages, messages)

        {:noreply, socket}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    if String.trim(message) != "" do
      user = socket.assigns.user
      conversation_id = get_conversation_id(socket.assigns.current_conversation)

      socket = assign(socket, :loading, true)

      # Process message asynchronously
      send(self(), {:process_message, user.id, conversation_id, message})

      {:noreply, assign(socket, :message_input, "")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("new_conversation", _params, socket) do
    user = socket.assigns.user

    case AI.create_conversation(%{user_id: user.id, title: "New Conversation"}) do
      {:ok, conversation} ->
        conversations = AI.list_conversations(user.id)

        socket =
          socket
          |> assign(:conversations, conversations)
          |> assign(:current_conversation, conversation)
          |> assign(:messages, [])

        {:noreply, push_patch(socket, to: ~p"/Admin/chats/#{conversation.id}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create conversation")}
    end
  end

  def handle_event("connect_google", _params, socket) do
    # Redirect to Google OAuth
    {:noreply, redirect(socket, external: "/auth/google")}
  end

  def handle_event("connect_hubspot", _params, socket) do
    # Redirect to HubSpot OAuth
    {:noreply, redirect(socket, external: "/auth/hubspot")}
  end

  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, :message_input, message)}
  end

  @impl true
  def handle_info({:process_message, user_id, conversation_id, message}, socket) do
    case Agent.process_message(user_id, conversation_id, message) do
      {:ok, assistant_message} ->
        # Refresh messages, conversation, and conversations list
        conversation = socket.assigns.current_conversation || AI.get_conversation!(assistant_message.conversation_id)
        messages = AI.list_messages(conversation.id)
        conversations = AI.list_conversations(user_id) # Refresh to get updated titles

        socket =
          socket
          |> assign(:current_conversation, conversation)
          |> assign(:messages, messages)
          |> assign(:conversations, conversations) # Update conversations list
          |> assign(:loading, false)

        {:noreply, socket}

      {:error, reason} ->
        socket =
          socket
          |> assign(:loading, false)
          |> put_flash(:error, "Failed to process message: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  defp get_conversation_id(nil), do: nil
  defp get_conversation_id(conversation), do: conversation.id

  defp get_connected_services(user_id) do
    %{
      google: Auth.provider_connected?(user_id, "google"),
      hubspot: Auth.provider_connected?(user_id, "hubspot")
    }
  end
end
