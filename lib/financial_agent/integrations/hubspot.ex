defmodule FinincialTool.Integrations.HubSpot do
  @moduledoc """
  HubSpot CRM API integration for managing contacts, deals, and notes.
  """

  alias FinincialTool.Auth
  alias FinincialTool.RAG

  @hubspot_api_base "https://api.hubapi.com"

  @doc """
  Creates a new contact in HubSpot.
  """
  def create_contact(user_id, %{"email" => email} = params) do
    properties = build_contact_properties(params)

    with {:ok, token} <- get_valid_token(user_id),
         {:ok, response} <- send_hubspot_request(token, "crm/v3/objects/contacts", %{properties: properties}, :post) do

      # Store contact as document for RAG
      store_contact_as_document(user_id, response)

      {:ok, %{
        contact_id: response["id"],
        email: get_in(response, ["properties", "email"]),
        first_name: get_in(response, ["properties", "firstname"]),
        last_name: get_in(response, ["properties", "lastname"]),
        company: get_in(response, ["properties", "company"])
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Updates an existing contact in HubSpot.
  """
  def update_contact(user_id, contact_id, updates) do
    properties = build_contact_properties(updates)

    with {:ok, token} <- get_valid_token(user_id),
         {:ok, response} <- send_hubspot_request(token, "crm/v3/objects/contacts/#{contact_id}", %{properties: properties}, :patch) do

      {:ok, parse_contact(response)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Searches for contacts in HubSpot.
  """
  def search_contacts(user_id, query) do
    search_request = %{
      query: query,
      limit: 20,
      properties: ["email", "firstname", "lastname", "company", "phone", "lifecyclestage"]
    }

    with {:ok, token} <- get_valid_token(user_id),
         {:ok, response} <- send_hubspot_request(token, "crm/v3/objects/contacts/search", search_request, :post) do

      contacts = response["results"] || []

      # Store contacts as documents for RAG
      Enum.each(contacts, fn contact ->
        store_contact_as_document(user_id, contact)
      end)

      {:ok, Enum.map(contacts, &parse_contact/1)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Fetches all contacts for a user.
  """
  def fetch_contacts(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    params = %{
      limit: limit,
      properties: ["email", "firstname", "lastname", "company", "phone", "lifecyclestage", "lastmodifieddate"]
    }

    with {:ok, token} <- get_valid_token(user_id),
         {:ok, response} <- send_hubspot_request(token, "crm/v3/objects/contacts", params, :get) do

      contacts = response["results"] || []

      # Store contacts as documents for RAG
      Enum.each(contacts, fn contact ->
        store_contact_as_document(user_id, contact)
      end)

      {:ok, Enum.map(contacts, &parse_contact/1)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Creates a deal in HubSpot.
  """
  def create_deal(user_id, params) do
    properties = build_deal_properties(params)

    with {:ok, token} <- get_valid_token(user_id),
         {:ok, response} <- send_hubspot_request(token, "crm/v3/objects/deals", %{properties: properties}, :post) do

      {:ok, parse_deal(response)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Fetches deals for a user.
  """
  def fetch_deals(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    params = %{
      limit: limit,
      properties: ["dealname", "amount", "dealstage", "pipeline", "closedate"]
    }

    with {:ok, token} <- get_valid_token(user_id),
         {:ok, response} <- send_hubspot_request(token, "crm/v3/objects/deals", params, :get) do

      deals = response["results"] || []
      {:ok, Enum.map(deals, &parse_deal/1)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Creates a note associated with a contact.
  """
  def create_note(user_id, contact_id, note_content) do
    properties = %{
      "hs_note_body" => note_content,
      "hs_timestamp" => DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    }

    associations = [
      %{
        "to" => %{"id" => contact_id},
        "types" => [%{"associationCategory" => "HUBSPOT_DEFINED", "associationTypeId" => 202}]
      }
    ]

    request_body = %{
      properties: properties,
      associations: associations
    }

    with {:ok, token} <- get_valid_token(user_id),
         {:ok, response} <- send_hubspot_request(token, "crm/v3/objects/notes", request_body, :post) do

      {:ok, %{
        note_id: response["id"],
        content: note_content,
        created_at: response["createdAt"]
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_valid_token(user_id) do
    case Auth.get_oauth_token(user_id, "hubspot") do
      nil -> {:error, "HubSpot account not connected"}
      token -> Auth.refresh_token_if_needed(token)
    end
  end

  defp build_contact_properties(params) do
    properties = %{}

    properties = if params["email"], do: Map.put(properties, "email", params["email"]), else: properties
    properties = if params["first_name"], do: Map.put(properties, "firstname", params["first_name"]), else: properties
    properties = if params["last_name"], do: Map.put(properties, "lastname", params["last_name"]), else: properties
    properties = if params["company"], do: Map.put(properties, "company", params["company"]), else: properties
    properties = if params["phone"], do: Map.put(properties, "phone", params["phone"]), else: properties
    properties = if params["website"], do: Map.put(properties, "website", params["website"]), else: properties

    properties
  end

  defp build_deal_properties(params) do
    properties = %{}

    properties = if params["deal_name"], do: Map.put(properties, "dealname", params["deal_name"]), else: properties
    properties = if params["amount"], do: Map.put(properties, "amount", params["amount"]), else: properties
    properties = if params["stage"], do: Map.put(properties, "dealstage", params["stage"]), else: properties
    properties = if params["pipeline"], do: Map.put(properties, "pipeline", params["pipeline"]), else: properties
    properties = if params["close_date"], do: Map.put(properties, "closedate", params["close_date"]), else: properties

    properties
  end

  defp send_hubspot_request(token, endpoint, params, method) do
    url = "#{@hubspot_api_base}/#{endpoint}"
    headers = [
      {"Authorization", "Bearer #{token.access_token}"},
      {"Content-Type", "application/json"}
    ]

    case method do
      :get ->
        query_string = URI.encode_query(params)
        full_url = if query_string != "", do: "#{url}?#{query_string}", else: url

        case HTTPoison.get(full_url, headers) do
          {:ok, %{status_code: 200, body: body}} -> {:ok, Jason.decode!(body)}
          {:ok, %{status_code: code, body: body}} -> {:error, "HubSpot API error #{code}: #{body}"}
          {:error, reason} -> {:error, "HTTP request failed: #{inspect(reason)}"}
        end

      :post ->
        case HTTPoison.post(url, Jason.encode!(params), headers) do
          {:ok, %{status_code: 201, body: body}} -> {:ok, Jason.decode!(body)}
          {:ok, %{status_code: 200, body: body}} -> {:ok, Jason.decode!(body)}
          {:ok, %{status_code: code, body: body}} -> {:error, "HubSpot API error #{code}: #{body}"}
          {:error, reason} -> {:error, "HTTP request failed: #{inspect(reason)}"}
        end

      :patch ->
        case HTTPoison.patch(url, Jason.encode!(params), headers) do
          {:ok, %{status_code: 200, body: body}} -> {:ok, Jason.decode!(body)}
          {:ok, %{status_code: code, body: body}} -> {:error, "HubSpot API error #{code}: #{body}"}
          {:error, reason} -> {:error, "HTTP request failed: #{inspect(reason)}"}
        end
    end
  end

  defp parse_contact(contact) do
    properties = contact["properties"] || %{}

    %{
      id: contact["id"],
      email: properties["email"],
      first_name: properties["firstname"],
      last_name: properties["lastname"],
      company: properties["company"],
      phone: properties["phone"],
      lifecycle_stage: properties["lifecyclestage"],
      created_at: contact["createdAt"],
      updated_at: contact["updatedAt"]
    }
  end

  defp parse_deal(deal) do
    properties = deal["properties"] || %{}

    %{
      id: deal["id"],
      deal_name: properties["dealname"],
      amount: properties["amount"],
      stage: properties["dealstage"],
      pipeline: properties["pipeline"],
      close_date: properties["closedate"],
      created_at: deal["createdAt"],
      updated_at: deal["updatedAt"]
    }
  end

  defp store_contact_as_document(user_id, contact) do
    properties = contact["properties"] || %{}

    content = build_contact_content(properties)

    RAG.process_document(%{
      user_id: user_id,
      source: "hubspot",
      source_id: contact["id"],
      document_type: "contact",
      title: "#{properties["firstname"]} #{properties["lastname"]} - #{properties["company"]}",
      content: content,
      metadata: %{
        email: properties["email"],
        company: properties["company"],
        lifecycle_stage: properties["lifecyclestage"],
        created_at: contact["createdAt"]
      }
    })
  end

  defp build_contact_content(properties) do
    name = "#{properties["firstname"]} #{properties["lastname"]}" |> String.trim()

    company_text = if properties["company"], do: "\nCompany: #{properties["company"]}", else: ""
    phone_text = if properties["phone"], do: "\nPhone: #{properties["phone"]}", else: ""
    stage_text = if properties["lifecyclestage"], do: "\nLifecycle Stage: #{properties["lifecyclestage"]}", else: ""

    """
    Contact: #{name}
    Email: #{properties["email"]}#{company_text}#{phone_text}#{stage_text}
    """
  end
end
