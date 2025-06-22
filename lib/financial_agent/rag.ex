defmodule FinancialAgent.RAG do
  @moduledoc """
  RAG (Retrieval Augmented Generation) module for document search and embeddings.
  """

  import Ecto.Query, warn: false
  alias FinancialAgent.Repo
  alias FinancialAgent.RAG.{Document, Embedding}

  @doc """
  Searches for documents using text similarity (fallback without pgvector).
  """
  def search_documents(user_id, query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    threshold = Keyword.get(opts, :threshold, 0.3)

    with {:ok, query_embedding} <- generate_embedding(query) do
      # Get all embeddings for the user and calculate similarity in Elixir
      embeddings =
        from(e in Embedding,
          join: d in Document, on: d.id == e.document_id,
          where: d.user_id == ^user_id,
          select: %{
            document: d,
            embedding: e.embedding,
            content_chunk: e.content_chunk
          }
        )
        |> Repo.all()

      results =
        embeddings
        |> Enum.map(fn item ->
          case Jason.decode(item.embedding) do
            {:ok, embedding_vector} ->
              similarity = cosine_similarity(query_embedding, embedding_vector)
              %{
                document: item.document,
                similarity: similarity,
                content_chunk: item.content_chunk
              }
            {:error, _} ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.filter(fn result -> result.similarity >= threshold end)
        |> Enum.sort_by(& &1.similarity, :desc)
        |> Enum.take(limit)

      {:ok, results}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Processes and stores a document with embeddings.
  """
  def process_document(attrs) do
    with {:ok, document} <- create_document(attrs),
         {:ok, chunks} <- chunk_content(document.content),
         {:ok, _embeddings} <- create_embeddings(document, chunks) do
      {:ok, document}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Creates a document record.
  """
  def create_document(attrs) do
    %Document{}
    |> Document.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a document record.
  """
  def update_document(%Document{} = document, attrs) do
    document
    |> Document.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets documents for a user by source.
  """
  def list_documents(user_id, opts \\ []) do
    query = Document |> where([d], d.user_id == ^user_id)

    query =
      case Keyword.get(opts, :source) do
        nil -> query
        source -> where(query, [d], d.source == ^source)
      end

    query =
      case Keyword.get(opts, :document_type) do
        nil -> query
        doc_type -> where(query, [d], d.document_type == ^doc_type)
      end

    query
    |> order_by([d], desc: d.inserted_at)
    |> Repo.all()
  end

  @doc """
  Deletes a document and its embeddings.
  """
  def delete_document(%Document{} = document) do
    Repo.delete(document)
  end

  defp chunk_content(content, chunk_size \\ 1000) do
    chunks =
      content
      |> String.split(~r/\n\n|\. /, trim: true)
      |> Enum.chunk_every(chunk_size)
      |> Enum.map(&Enum.join(&1, " "))
      |> Enum.with_index()

    {:ok, chunks}
  end

  defp create_embeddings(document, chunks) do
    embeddings_data =
      Enum.map(chunks, fn {chunk, index} ->
        case generate_embedding(chunk) do
          {:ok, embedding} ->
            %{
              document_id: document.id,
              content_chunk: chunk,
              embedding: Jason.encode!(embedding),  # Store as JSON string
              chunk_index: index,
              inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
              updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
            }
          {:error, _reason} ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    case Repo.insert_all(Embedding, embeddings_data) do
      {count, _} when count > 0 -> {:ok, count}
      _ -> {:error, :failed_to_create_embeddings}
    end
  end

  # Cosine similarity calculation for embeddings
  defp cosine_similarity(vec1, vec2) when is_list(vec1) and is_list(vec2) do
    if length(vec1) != length(vec2) do
      0.0
    else
      dot_product = Enum.zip(vec1, vec2) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
      magnitude1 = :math.sqrt(Enum.map(vec1, fn x -> x * x end) |> Enum.sum())
      magnitude2 = :math.sqrt(Enum.map(vec2, fn x -> x * x end) |> Enum.sum())

      if magnitude1 == 0.0 or magnitude2 == 0.0 do
        0.0
      else
        dot_product / (magnitude1 * magnitude2)
      end
    end
  end

  defp generate_embedding(text) do
    case OpenAI.embeddings(
      model: "text-embedding-ada-002",
      input: text
    ) do
      # Handle old string-keyed response format
      {:ok, %{"data" => [%{"embedding" => embedding} | _]}} ->
        {:ok, embedding}

      # Handle new atom-keyed response format
      {:ok, %{data: [%{"embedding" => embedding} | _]}} ->
        {:ok, embedding}

      # Handle mixed format (atoms at top level, strings in data)
      {:ok, response} when is_map(response) ->
        case get_in(response, [:data]) || get_in(response, ["data"]) do
          [%{"embedding" => embedding} | _] -> {:ok, embedding}
          _ -> {:error, "Invalid embedding response format"}
        end

      {:error, reason} ->
        {:error, reason}

      # Fallback for any other unexpected format
      other ->
        {:error, "Unexpected response format: #{inspect(other)}"}
    end
  end

  @doc """
  Syncs documents from external sources.
  """
  def sync_user_documents(user_id) do
    # This would be called by background jobs to sync data
    with {:ok, _gmail_docs} <- sync_gmail_documents(user_id),
         {:ok, _hubspot_docs} <- sync_hubspot_documents(user_id),
         {:ok, _calendar_docs} <- sync_calendar_documents(user_id) do
      {:ok, :synced}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp sync_gmail_documents(user_id) do
    # Implementation would fetch emails and create documents
    {:ok, []}
  end

  defp sync_hubspot_documents(user_id) do
    # Implementation would fetch contacts/notes and create documents
    {:ok, []}
  end

  defp sync_calendar_documents(user_id) do
    # Implementation would fetch calendar events and create documents
    {:ok, []}
  end
end
