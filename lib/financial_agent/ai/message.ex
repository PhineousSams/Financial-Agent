defmodule FinancialAgent.AI.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias FinancialAgent.AI.Conversation

  schema "messages" do
    field :role, :string
    field :content, :string
    field :metadata, :map, default: %{}
    field :tokens_used, :integer
    field :function_calls, :map

    belongs_to :conversation, Conversation, foreign_key: :conversation_id

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:conversation_id, :role, :content, :metadata, :tokens_used, :function_calls])
    |> validate_required([:conversation_id, :role, :content])
    |> validate_inclusion(:role, ["user", "assistant", "system", "function"])
    |> foreign_key_constraint(:conversation_id)
  end
end
