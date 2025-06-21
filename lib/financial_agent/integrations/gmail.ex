defmodule FinancialAgent.Integrations.Gmail do
  @moduledoc """
  Gmail API integration for sending emails and fetching messages.
  """

  alias FinancialAgent.Auth
  alias FinancialAgent.RAG

  @gmail_api_base "https://gmail.googleapis.com/gmail/v1"

  @doc """
  Sends an email via Gmail API.
  """
  def send_email(user_id, %{"to" => to, "subject" => subject, "body" => body}) do
    with {:ok, token} <- get_valid_token(user_id),
         {:ok, message} <- compose_message(to, subject, body),
         {:ok, response} <- send_gmail_request(token, "messages/send", message) do
      {:ok, %{
        recipient: to,
        subject: subject,
        message_id: response["id"]
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Fetches recent emails for a user.
  """
  def fetch_recent_emails(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    with {:ok, token} <- get_valid_token(user_id),
         {:ok, message_list} <- get_message_list(token, limit),
         {:ok, messages} <- fetch_message_details(token, message_list["messages"] || []) do

      # Store messages as documents for RAG
      Enum.each(messages, fn message ->
        store_email_as_document(user_id, message)
      end)

      {:ok, messages}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Searches emails by query.
  """
  def search_emails(user_id, query) do
    with {:ok, token} <- get_valid_token(user_id),
         {:ok, response} <- send_gmail_request(token, "messages", %{q: query}) do
      message_ids = Enum.map(response["messages"] || [], & &1["id"])
      fetch_message_details(token, message_ids)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_valid_token(user_id) do
    case Auth.get_oauth_token(user_id, "google") do
      nil -> {:error, "Google account not connected"}
      token -> Auth.refresh_token_if_needed(token)
    end
  end

  defp compose_message(to, subject, body) do
    email_content = """
    To: #{to}
    Subject: #{subject}
    Content-Type: text/plain; charset=utf-8

    #{body}
    """

    encoded_message = Base.url_encode64(email_content, padding: false)
    {:ok, %{raw: encoded_message}}
  end

  defp send_gmail_request(token, endpoint, body \\ %{}) do
    url = "#{@gmail_api_base}/users/me/#{endpoint}"
    headers = [
      {"Authorization", "Bearer #{token.access_token}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(url, Jason.encode!(body), headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        {:ok, Jason.decode!(response_body)}

      {:ok, %{status_code: status_code, body: error_body}} ->
        {:error, "Gmail API error #{status_code}: #{error_body}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp get_message_list(token, limit) do
    send_gmail_request(token, "messages", %{maxResults: limit})
  end

  defp fetch_message_details(token, message_ids) when is_list(message_ids) do
    messages =
      Enum.map(message_ids, fn message_id ->
        case send_gmail_request(token, "messages/#{message_id}") do
          {:ok, message} -> parse_message(message)
          {:error, _} -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, messages}
  end

  defp parse_message(gmail_message) do
    headers = get_in(gmail_message, ["payload", "headers"]) || []

    subject = find_header(headers, "Subject")
    from = find_header(headers, "From")
    to = find_header(headers, "To")
    date = find_header(headers, "Date")

    body = extract_body(gmail_message["payload"])

    %{
      id: gmail_message["id"],
      thread_id: gmail_message["threadId"],
      subject: subject,
      from: from,
      to: to,
      date: date,
      body: body,
      snippet: gmail_message["snippet"]
    }
  end

  defp find_header(headers, name) do
    case Enum.find(headers, fn header -> header["name"] == name end) do
      nil -> nil
      header -> header["value"]
    end
  end

  defp extract_body(payload) do
    cond do
      payload["body"]["data"] ->
        Base.decode64!(payload["body"]["data"], padding: false)

      payload["parts"] ->
        payload["parts"]
        |> Enum.find(fn part -> part["mimeType"] == "text/plain" end)
        |> case do
          nil -> ""
          part -> Base.decode64!(part["body"]["data"], padding: false)
        end

      true ->
        ""
    end
  end

  defp store_email_as_document(user_id, message) do
    content = "Subject: #{message.subject}\nFrom: #{message.from}\nTo: #{message.to}\n\n#{message.body}"

    RAG.process_document(%{
      user_id: user_id,
      source: "gmail",
      source_id: message.id,
      document_type: "email",
      title: message.subject,
      content: content,
      metadata: %{
        from: message.from,
        to: message.to,
        date: message.date,
        thread_id: message.thread_id
      }
    })
  end
end
