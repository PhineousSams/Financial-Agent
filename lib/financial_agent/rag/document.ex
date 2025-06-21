defmodule FinincialTool.RAG.Document do
  use Ecto.Schema
  import Ecto.Changeset

  alias FinincialTool.Accounts.User
  alias FinincialTool.RAG.Embedding

  schema "documents" do
    field :source, :string
    field :source_id, :string
    field :document_type, :string
    field :title, :string
    field :content, :string
    field :metadata, :map, default: %{}
    field :processed_at, :utc_datetime
    field :last_synced_at, :utc_datetime

    belongs_to :user, User, foreign_key: :user_id, references: :id
    has_many :embeddings, Embedding, foreign_key: :document_id

    timestamps()
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [
      :user_id, :source, :source_id, :document_type, :title, :content,
      :metadata, :processed_at, :last_synced_at
    ])
    |> validate_required([:user_id, :source, :source_id, :document_type])
    |> validate_inclusion(:source, ["gmail", "hubspot", "calendar"])
    |> validate_inclusion(:document_type, ["email", "contact", "event", "note", "deal"])
    |> unique_constraint([:user_id, :source, :source_id])
    |> foreign_key_constraint(:user_id)
  end

  def mark_processed(document) do
    changeset(document, %{processed_at: DateTime.utc_now()})
  end

  def mark_synced(document) do
    changeset(document, %{last_synced_at: DateTime.utc_now()})
  end
end
