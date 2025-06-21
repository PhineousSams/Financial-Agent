defmodule FinancialAgent.AI.Agent do
  @moduledoc """
  The AI Agent module that handles conversations with OpenAI and function calling.
  """

  alias FinancialAgent.AI
  alias FinancialAgent.AI.{Conversation, Message}
  alias FinancialAgent.Integrations.{Gmail, Calendar, HubSpot}
  alias FinancialAgent.RAG

  @system_prompt """
  You are an AI assistant for financial advisors. You help manage client relationships,
  schedule meetings, send emails, and organize information from Gmail, Google Calendar, and HubSpot CRM.

  You have access to the following tools:
  - search_documents: Search through emails, contacts, and notes
  - send_email: Send emails via Gmail
  - schedule_meeting: Create calendar events
  - create_hubspot_contact: Create new contacts in HubSpot
  - update_hubspot_contact: Update existing contacts
  - search_hubspot_contacts: Search for contacts in HubSpot
  - disambiguate_contact: Help resolve ambiguous contact references

  Always be helpful, professional, and accurate. When you're unsure about something, ask for clarification.
  If you need to perform actions that might have significant consequences, confirm with the user first.
  """

  @doc """
  Processes a user message and generates an AI response.
  """
  def process_message(user_id, conversation_id, user_message) do
    with {:ok, conversation} <- get_or_create_conversation(user_id, conversation_id),
         {:ok, _user_msg} <- AI.create_message(%{
           conversation_id: conversation.id,
           role: "user",
           content: user_message
         }),
         {:ok, updated_conversation} <- maybe_update_conversation_title(conversation, user_message),
         {:ok, messages} <- build_message_history(updated_conversation.id),
         {:ok, ai_response} <- call_openai(messages, user_id),
         {:ok, assistant_msg} <- AI.create_message(%{
           conversation_id: updated_conversation.id,
           role: "assistant",
           content: ai_response.content,
           tokens_used: ai_response.tokens_used,
           function_calls: ai_response.function_calls
         }) do
      {:ok, assistant_msg}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_or_create_conversation(user_id, nil) do
    AI.create_conversation(%{
      user_id: user_id,
      title: "New Conversation"
    })
  end

  defp get_or_create_conversation(user_id, conversation_id) do
    case AI.get_user_conversation(user_id, conversation_id) do
      nil -> {:error, :conversation_not_found}
      conversation -> {:ok, conversation}
    end
  end

  defp maybe_update_conversation_title(conversation, user_message) do
    # Only update title if it's still "New Conversation" and this is likely the first real message
    if conversation.title == "New Conversation" and String.length(String.trim(user_message)) > 0 do
      # Generate a meaningful title from the user's message
      title = generate_conversation_title(user_message)
      case AI.update_conversation(conversation, %{title: title}) do
        {:ok, updated_conversation} -> {:ok, updated_conversation}
        {:error, _} -> {:ok, conversation} # Fall back to original if update fails
      end
    else
      {:ok, conversation}
    end
  end

  defp generate_conversation_title(user_message) do
    # Clean and truncate the message to create a meaningful title
    cleaned_message = user_message
                     |> String.trim()
                     |> String.replace(~r/\s+/, " ") # Replace multiple spaces with single space
                     |> String.slice(0, 50) # Limit to 50 characters

    # Add ellipsis if truncated
    if String.length(user_message) > 50 do
      cleaned_message <> "..."
    else
      cleaned_message
    end
  end

  defp build_message_history(conversation_id) do
    messages = AI.list_messages(conversation_id)

    openai_messages = [
      %{role: "system", content: @system_prompt}
      | Enum.map(messages, fn msg ->
          %{role: msg.role, content: msg.content}
        end)
    ]

    {:ok, openai_messages}
  end

  defp call_openai(messages, user_id) do
    functions = define_functions()

    case OpenAI.chat_completion(
      model: "gpt-3.5-turbo",
      messages: messages,
      functions: functions,
      function_call: "auto",
      temperature: 0.7,
      max_tokens: 1000
    ) do
      {:ok, response} ->
        handle_openai_response(response, user_id)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_openai_response(%{"choices" => [choice | _]} = response, user_id) do
    message = choice["message"]

    case message do
      %{"function_call" => function_call} ->
        # Handle function calling
        handle_function_call(function_call, user_id, response)

      %{"content" => content} ->
        # Regular text response
        {:ok, %{
          content: content,
          tokens_used: get_in(response, ["usage", "total_tokens"]),
          function_calls: nil
        }}
    end
  end

  defp handle_function_call(function_call, user_id, response) do
    function_name = function_call["name"]
    arguments = Jason.decode!(function_call["arguments"])

    case execute_function(function_name, arguments, user_id) do
      {:ok, result} ->
        # Return the function result as the AI response
        {:ok, %{
          content: format_function_result(function_name, result),
          tokens_used: get_in(response, ["usage", "total_tokens"]),
          function_calls: %{function_name => arguments}
        }}

      {:error, reason} ->
        {:ok, %{
          content: "I encountered an error while trying to #{function_name}: #{reason}",
          tokens_used: get_in(response, ["usage", "total_tokens"]),
          function_calls: %{function_name => arguments}
        }}
    end
  end

  defp execute_function("search_documents", %{"query" => query}, user_id) do
    RAG.search_documents(user_id, query)
  end

  defp execute_function("send_email", args, user_id) do
    Gmail.send_email(user_id, args)
  end

  defp execute_function("schedule_meeting", args, user_id) do
    Calendar.create_event(user_id, args)
  end

  defp execute_function("create_hubspot_contact", args, user_id) do
    HubSpot.create_contact(user_id, args)
  end

  defp execute_function("update_hubspot_contact", args, user_id) do
    HubSpot.update_contact(user_id, args)
  end

  defp execute_function("search_hubspot_contacts", %{"query" => query}, user_id) do
    HubSpot.search_contacts(user_id, query)
  end

  defp execute_function("disambiguate_contact", args, user_id) do
    # Handle contact disambiguation logic
    {:ok, "Please specify which contact you mean by providing more details."}
  end

  defp execute_function(function_name, _args, _user_id) do
    {:error, "Unknown function: #{function_name}"}
  end

  defp format_function_result("search_documents", results) do
    case results do
      [] -> "I couldn't find any relevant documents for your query."
      documents ->
        "I found #{length(documents)} relevant documents:\n\n" <>
        Enum.map_join(documents, "\n\n", fn doc ->
          "#{doc.title}: #{String.slice(doc.content, 0, 200)}..."
        end)
    end
  end

  defp format_function_result("send_email", result) do
    "Email sent successfully to #{result.recipient}"
  end

  defp format_function_result("schedule_meeting", result) do
    "Meeting scheduled: #{result.summary} on #{result.start_time}"
  end

  defp format_function_result("create_hubspot_contact", result) do
    "Created new contact: #{result.first_name} #{result.last_name}"
  end

  defp format_function_result(_function_name, result) do
    "Action completed successfully: #{inspect(result)}"
  end

  defp define_functions do
    [
      %{
        name: "search_documents",
        description: "Search through emails, contacts, and notes",
        parameters: %{
          type: "object",
          properties: %{
            query: %{type: "string", description: "Search query"}
          },
          required: ["query"]
        }
      },
      %{
        name: "send_email",
        description: "Send an email via Gmail",
        parameters: %{
          type: "object",
          properties: %{
            to: %{type: "string", description: "Recipient email address"},
            subject: %{type: "string", description: "Email subject"},
            body: %{type: "string", description: "Email body"}
          },
          required: ["to", "subject", "body"]
        }
      },
      %{
        name: "schedule_meeting",
        description: "Create a calendar event",
        parameters: %{
          type: "object",
          properties: %{
            summary: %{type: "string", description: "Meeting title"},
            start_time: %{type: "string", description: "Start time (ISO 8601)"},
            end_time: %{type: "string", description: "End time (ISO 8601)"},
            attendees: %{type: "array", items: %{type: "string"}, description: "Attendee emails"}
          },
          required: ["summary", "start_time", "end_time"]
        }
      },
      %{
        name: "create_hubspot_contact",
        description: "Create a new contact in HubSpot",
        parameters: %{
          type: "object",
          properties: %{
            email: %{type: "string", description: "Contact email"},
            first_name: %{type: "string", description: "First name"},
            last_name: %{type: "string", description: "Last name"},
            company: %{type: "string", description: "Company name"}
          },
          required: ["email"]
        }
      },
      %{
        name: "search_hubspot_contacts",
        description: "Search for contacts in HubSpot",
        parameters: %{
          type: "object",
          properties: %{
            query: %{type: "string", description: "Search query"}
          },
          required: ["query"]
        }
      }
    ]
  end
end
