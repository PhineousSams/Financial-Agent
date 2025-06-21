defmodule FinincialAgent.Integrations.Calendar do
  @moduledoc """
  Google Calendar API integration for managing calendar events.
  """

  alias FinincialAgent.Auth
  alias FinincialAgent.RAG

  @calendar_api_base "https://www.googleapis.com/calendar/v3"

  @doc """
  Creates a calendar event.
  """
  def create_event(user_id, %{"summary" => summary, "start_time" => start_time, "end_time" => end_time} = params) do
    with {:ok, token} <- get_valid_token(user_id),
         {:ok, event_data} <- build_event_data(params),
         {:ok, response} <- send_calendar_request(token, "events", event_data, :post) do

      # Store event as document for RAG
      store_event_as_document(user_id, response)

      {:ok, %{
        event_id: response["id"],
        summary: response["summary"],
        start_time: response["start"]["dateTime"],
        end_time: response["end"]["dateTime"],
        html_link: response["htmlLink"]
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Fetches upcoming events for a user.
  """
  def fetch_upcoming_events(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    time_min = Keyword.get(opts, :time_min, DateTime.utc_now())

    params = %{
      timeMin: DateTime.to_iso8601(time_min),
      maxResults: limit,
      singleEvents: true,
      orderBy: "startTime"
    }

    with {:ok, token} <- get_valid_token(user_id),
         {:ok, response} <- send_calendar_request(token, "events", params, :get) do

      events = response["items"] || []

      # Store events as documents for RAG
      Enum.each(events, fn event ->
        store_event_as_document(user_id, event)
      end)

      {:ok, Enum.map(events, &parse_event/1)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Finds free time slots for scheduling.
  """
  def find_free_time(user_id, date, duration_minutes \\ 60) do
    start_of_day = DateTime.new!(date, ~T[09:00:00], "Etc/UTC")
    end_of_day = DateTime.new!(date, ~T[17:00:00], "Etc/UTC")

    params = %{
      timeMin: DateTime.to_iso8601(start_of_day),
      timeMax: DateTime.to_iso8601(end_of_day),
      singleEvents: true,
      orderBy: "startTime"
    }

    with {:ok, token} <- get_valid_token(user_id),
         {:ok, response} <- send_calendar_request(token, "events", params, :get) do

      busy_times = extract_busy_times(response["items"] || [])
      free_slots = calculate_free_slots(start_of_day, end_of_day, busy_times, duration_minutes)

      {:ok, free_slots}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Updates an existing calendar event.
  """
  def update_event(user_id, event_id, updates) do
    with {:ok, token} <- get_valid_token(user_id),
         {:ok, current_event} <- send_calendar_request(token, "events/#{event_id}", %{}, :get),
         {:ok, updated_data} <- merge_event_updates(current_event, updates),
         {:ok, response} <- send_calendar_request(token, "events/#{event_id}", updated_data, :put) do

      {:ok, parse_event(response)}
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

  defp build_event_data(params) do
    event_data = %{
      summary: params["summary"],
      start: %{
        dateTime: params["start_time"],
        timeZone: "UTC"
      },
      end: %{
        dateTime: params["end_time"],
        timeZone: "UTC"
      }
    }

    event_data =
      case params["description"] do
        nil -> event_data
        desc -> Map.put(event_data, :description, desc)
      end

    event_data =
      case params["location"] do
        nil -> event_data
        loc -> Map.put(event_data, :location, loc)
      end

    event_data =
      case params["attendees"] do
        nil -> event_data
        attendees when is_list(attendees) ->
          attendee_list = Enum.map(attendees, fn email -> %{email: email} end)
          Map.put(event_data, :attendees, attendee_list)
        _ -> event_data
      end

    {:ok, event_data}
  end

  defp send_calendar_request(token, endpoint, params, method) do
    calendar_id = "primary"
    url = "#{@calendar_api_base}/calendars/#{calendar_id}/#{endpoint}"

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
          {:ok, %{status_code: code, body: body}} -> {:error, "Calendar API error #{code}: #{body}"}
          {:error, reason} -> {:error, "HTTP request failed: #{inspect(reason)}"}
        end

      :post ->
        case HTTPoison.post(url, Jason.encode!(params), headers) do
          {:ok, %{status_code: 200, body: body}} -> {:ok, Jason.decode!(body)}
          {:ok, %{status_code: code, body: body}} -> {:error, "Calendar API error #{code}: #{body}"}
          {:error, reason} -> {:error, "HTTP request failed: #{inspect(reason)}"}
        end

      :put ->
        case HTTPoison.put(url, Jason.encode!(params), headers) do
          {:ok, %{status_code: 200, body: body}} -> {:ok, Jason.decode!(body)}
          {:ok, %{status_code: code, body: body}} -> {:error, "Calendar API error #{code}: #{body}"}
          {:error, reason} -> {:error, "HTTP request failed: #{inspect(reason)}"}
        end
    end
  end

  defp parse_event(event) do
    %{
      id: event["id"],
      summary: event["summary"],
      description: event["description"],
      location: event["location"],
      start_time: get_in(event, ["start", "dateTime"]) || get_in(event, ["start", "date"]),
      end_time: get_in(event, ["end", "dateTime"]) || get_in(event, ["end", "date"]),
      attendees: parse_attendees(event["attendees"]),
      status: event["status"],
      html_link: event["htmlLink"]
    }
  end

  defp parse_attendees(nil), do: []
  defp parse_attendees(attendees) when is_list(attendees) do
    Enum.map(attendees, fn attendee ->
      %{
        email: attendee["email"],
        display_name: attendee["displayName"],
        response_status: attendee["responseStatus"]
      }
    end)
  end

  defp extract_busy_times(events) do
    Enum.map(events, fn event ->
      start_time = get_in(event, ["start", "dateTime"])
      end_time = get_in(event, ["end", "dateTime"])

      if start_time && end_time do
        {DateTime.from_iso8601(start_time), DateTime.from_iso8601(end_time)}
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn {{:ok, start_dt, _}, {:ok, end_dt, _}} -> {start_dt, end_dt} end)
  end

  defp calculate_free_slots(start_time, end_time, busy_times, duration_minutes) do
    duration_seconds = duration_minutes * 60

    # Sort busy times by start time
    sorted_busy = Enum.sort_by(busy_times, fn {start_dt, _} -> start_dt end)

    # Find gaps between busy times
    free_slots = []
    current_time = start_time

    Enum.reduce(sorted_busy, {current_time, free_slots}, fn {busy_start, busy_end}, {current, slots} ->
      # Check if there's a gap before this busy time
      gap_duration = DateTime.diff(busy_start, current)

      new_slots =
        if gap_duration >= duration_seconds do
          slot_end = DateTime.add(current, duration_seconds)
          [%{start: current, end: slot_end} | slots]
        else
          slots
        end

      {busy_end, new_slots}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp merge_event_updates(current_event, updates) do
    merged =
      current_event
      |> Map.merge(updates)

    {:ok, merged}
  end

  defp store_event_as_document(user_id, event) do
    content = build_event_content(event)

    RAG.process_document(%{
      user_id: user_id,
      source: "calendar",
      source_id: event["id"],
      document_type: "event",
      title: event["summary"],
      content: content,
      metadata: %{
        start_time: get_in(event, ["start", "dateTime"]),
        end_time: get_in(event, ["end", "dateTime"]),
        location: event["location"],
        attendees: event["attendees"]
      }
    })
  end

  defp build_event_content(event) do
    attendees_text =
      case event["attendees"] do
        nil -> ""
        attendees ->
          attendee_emails = Enum.map(attendees, & &1["email"])
          "\nAttendees: #{Enum.join(attendee_emails, ", ")}"
      end

    location_text =
      case event["location"] do
        nil -> ""
        location -> "\nLocation: #{location}"
      end

    description_text =
      case event["description"] do
        nil -> ""
        desc -> "\nDescription: #{desc}"
      end

    """
    Event: #{event["summary"]}
    Start: #{get_in(event, ["start", "dateTime"])}
    End: #{get_in(event, ["end", "dateTime"])}#{location_text}#{attendees_text}#{description_text}
    """
  end
end
