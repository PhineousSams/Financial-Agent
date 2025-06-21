defmodule FinincialAgent.AI.Task do
  use Ecto.Schema
  import Ecto.Changeset

  alias FinincialAgent.Accounts.User
  alias FinincialAgent.AI.Conversation

  schema "tasks" do
    field :title, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :task_type, :string
    field :context, :map, default: %{}
    field :result, :map
    field :error_message, :string
    field :scheduled_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :retry_count, :integer, default: 0
    field :max_retries, :integer, default: 3

    belongs_to :user, User, foreign_key: :user_id, references: :id
    belongs_to :conversation, Conversation, foreign_key: :conversation_id

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :user_id, :conversation_id, :title, :description, :status, :task_type,
      :context, :result, :error_message, :scheduled_at, :completed_at,
      :retry_count, :max_retries
    ])
    |> validate_required([:user_id, :title, :task_type])
    |> validate_inclusion(:status, ["pending", "in_progress", "completed", "failed", "cancelled"])
    |> validate_inclusion(:task_type, ["email", "calendar", "hubspot", "general"])
    |> validate_number(:retry_count, greater_than_or_equal_to: 0)
    |> validate_number(:max_retries, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:conversation_id)
  end

  def mark_completed(task, result \\ %{}) do
    changeset(task, %{
      status: "completed",
      result: result,
      completed_at: DateTime.utc_now()
    })
  end

  def mark_failed(task, error_message) do
    changeset(task, %{
      status: "failed",
      error_message: error_message,
      retry_count: task.retry_count + 1
    })
  end

  def can_retry?(%__MODULE__{retry_count: retry_count, max_retries: max_retries}) do
    retry_count < max_retries
  end
end
