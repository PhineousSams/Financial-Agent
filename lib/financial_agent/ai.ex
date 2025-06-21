defmodule FinincialAgent.AI do
  @moduledoc """
  The AI context for managing conversations, messages, and AI-powered features.
  """

  import Ecto.Query, warn: false
  alias FinincialAgent.Repo
  alias FinincialAgent.AI.{Conversation, Message, Task, OngoingInstruction}

  ## Conversations

  @doc """
  Returns the list of conversations for a user.
  """
  def list_conversations(user_id) do
    Conversation
    |> where([c], c.user_id == ^user_id)
    |> order_by([c], desc: c.updated_at)
    |> Repo.all()
  end

  @doc """
  Gets a single conversation.
  """
  def get_conversation!(id), do: Repo.get!(Conversation, id)

  @doc """
  Gets a conversation by user and conversation id.
  """
  def get_user_conversation(user_id, conversation_id) do
    Conversation
    |> where([c], c.user_id == ^user_id and c.id == ^conversation_id)
    |> Repo.one()
  end

  @doc """
  Creates a conversation.
  """
  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a conversation.
  """
  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a conversation.
  """
  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  ## Messages

  @doc """
  Returns the list of messages for a conversation.
  """
  def list_messages(conversation_id) do
    Message
    |> where([m], m.conversation_id == ^conversation_id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end

  @doc """
  Creates a message.
  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  ## Tasks

  @doc """
  Returns the list of tasks for a user.
  """
  def list_tasks(user_id, opts \\ []) do
    query = Task |> where([t], t.user_id == ^user_id)

    query =
      case Keyword.get(opts, :status) do
        nil -> query
        status -> where(query, [t], t.status == ^status)
      end

    query
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single task.
  """
  def get_task!(id), do: Repo.get!(Task, id)

  @doc """
  Creates a task.
  """
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.
  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  ## Ongoing Instructions

  @doc """
  Returns the list of active ongoing instructions for a user.
  """
  def list_active_instructions(user_id) do
    OngoingInstruction
    |> where([i], i.user_id == ^user_id and i.active == true)
    |> order_by([i], desc: i.priority, desc: i.inserted_at)
    |> Repo.all()
  end

  @doc """
  Creates an ongoing instruction.
  """
  def create_ongoing_instruction(attrs \\ %{}) do
    %OngoingInstruction{}
    |> OngoingInstruction.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an ongoing instruction.
  """
  def update_ongoing_instruction(%OngoingInstruction{} = instruction, attrs) do
    instruction
    |> OngoingInstruction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deactivates an ongoing instruction.
  """
  def deactivate_instruction(%OngoingInstruction{} = instruction) do
    update_ongoing_instruction(instruction, %{active: false})
  end
end
