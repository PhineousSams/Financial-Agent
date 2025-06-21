defmodule FinincialAgent.AI.OngoingInstruction do
  use Ecto.Schema
  import Ecto.Changeset

  alias FinincialAgent.Accounts.User

  schema "ongoing_instructions" do
    field :instruction, :string
    field :trigger_conditions, :map, default: %{}
    field :actions, :map, default: %{}
    field :active, :boolean, default: true
    field :priority, :integer, default: 0
    field :execution_count, :integer, default: 0
    field :last_executed_at, :utc_datetime

    belongs_to :user, User, foreign_key: :user_id, references: :id

    timestamps()
  end

  @doc false
  def changeset(ongoing_instruction, attrs) do
    ongoing_instruction
    |> cast(attrs, [
      :user_id, :instruction, :trigger_conditions, :actions, :active,
      :priority, :execution_count, :last_executed_at
    ])
    |> validate_required([:user_id, :instruction])
    |> validate_number(:priority, greater_than_or_equal_to: 0)
    |> validate_number(:execution_count, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:user_id)
  end

  def increment_execution_count(instruction) do
    changeset(instruction, %{
      execution_count: instruction.execution_count + 1,
      last_executed_at: DateTime.utc_now()
    })
  end
end
