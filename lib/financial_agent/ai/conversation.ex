defmodule FinincialAgent.AI.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias FinincialAgent.Accounts.User
  alias FinincialAgent.AI.Message

  schema "conversations" do
    field :title, :string
    field :status, :string, default: "active"
    field :metadata, :map, default: %{}

    belongs_to :user, User, foreign_key: :user_id, references: :id
    has_many :messages, Message, foreign_key: :conversation_id

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:user_id, :title, :status, :metadata])
    |> validate_required([:user_id])
    |> validate_inclusion(:status, ["active", "archived", "deleted"])
    |> foreign_key_constraint(:user_id)
  end
end
