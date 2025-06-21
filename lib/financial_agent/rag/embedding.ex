defmodule FinincialAgent.RAG.Embedding do
  use Ecto.Schema
  import Ecto.Changeset

  alias FinincialAgent.RAG.Document

  schema "embeddings" do
    field :content_chunk, :string
    field :embedding, :string  # Store as JSON string for now
    field :chunk_index, :integer, default: 0
    field :metadata, :map, default: %{}

    belongs_to :document, Document, foreign_key: :document_id

    timestamps()
  end

  @doc false
  def changeset(embedding, attrs) do
    embedding
    |> cast(attrs, [:document_id, :content_chunk, :embedding, :chunk_index, :metadata])
    |> validate_required([:document_id, :content_chunk, :embedding])
    |> validate_number(:chunk_index, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:document_id)
  end
end
