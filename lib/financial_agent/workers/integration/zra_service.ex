defmodule FinincialTool.Workers.Integration.ZraService do
  @moduledoc """
  Handles integration with the ZRA (Zambia Revenue Authority) API.
  Provides functionality for PRN (Payment Registration Number) operations.
  """

  # use PipeTo.Override
  require Logger

  alias FinincialTool.Repo
  alias FinincialTool.Logs.ServiceLogs
  alias FinincialTool.Workers.Helpers.ZraEncoder

  @doc """
  Retrieves pending PRNs based on the provided parameters.

  ## Parameters
    * params - Map containing query parameters:
      * tpin - Taxpayer Identification Number
      * queryType - Type of query (e.g., "TAXPAYER")
      * currencyCode - Currency code (defaults to "")
      * prnType - PRN type (defaults to "ALL")
      * startDate - Start date for the query (defaults to "")
      * endDate - End date for the query (defaults to "")

  ## Returns
    * `{:ok, result}` on success
    * `{:error, reason}` on failure
  """
  def get_pending_prns(params) do
    params= %{
      tpin: params["tpin"],
      queryType: params["queryType"],
      currencyCode: Map.get(params, "currencyCode", ""),
      prnType: Map.get(params, "prnType", "ALL"),
      startDate: Map.get(params, "startDate", ""),
      endDate: Map.get(params, "endDate", "")
    }
    %{
      service: "GET_PENDING_PRNS",
      req: params
    }
    |> ZraEncoder.encrypt_data()
    |> case do
      {:ok, payload} ->
        payload
        |> request()
        |> handle_encryption_result()
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Retrieves details for a specific PRN.

  ## Parameters
    * prn - Payment Registration Number

  ## Returns
    * `{:ok, result}` on success
    * `{:error, reason}` on failure
  """
  # FinincialTool.Integration.ZraService.get_prn_details("212410230720")
  def get_prn_details(prn) when is_binary(prn) do
    %{service: "GET_PRN_DETAILS", req: %{prn: prn}}
    |> ZraEncoder.encrypt_data()
    |> case do
      {:ok, payload} ->
        payload
        |> request()
        |> handle_encryption_result()
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Test function to get pending PRNs with hardcoded parameters.
  """
  # FinincialTool.Integration.ZraService.phin()
  def phin do
    params = %{
      "currencyCode" => "ZMW",
      "endDate" => "2025-04-29",
      "prnType" => "ALL",
      "queryType" => "TAXPAYER",
      "startDate" => "2025-01-28",
      "tpin" => "1001187851"
    }

    get_pending_prns(params)
  end

  # Private functions

  defp handle_encryption_result({:ok, resp}), do: normalize_amounts(resp)
  defp handle_encryption_result({:error, reason}), do: {:error, reason}

  defp normalize_amounts(resp) do
    case has_cd_tax_code?(resp) do
      true ->
        if needs_amount_conversion?(resp) do
          Logger.warn("IPS MALFORMATTED AMOUNT detected in response")
          convert_response_amounts(resp)
        else
          {:ok, resp}
        end
      false ->
        {:ok, resp}
    end
  end

  defp has_cd_tax_code?(resp) do
    breakdown = Map.get(resp, "breakdown", [])
    Enum.any?(breakdown, fn %{"taxCode" => code} -> code == "CD" end)
  end

  defp needs_amount_conversion?(resp) do
    breakdown = Map.get(resp, "breakdown", [])
    cd_item = Enum.find(breakdown, fn %{"taxCode" => code} -> code == "CD" end)

    if cd_item do
      cd_amount = Map.get(cd_item, "amount")
      String.contains?(to_string(cd_amount), "e")
    else
      false
    end
  end

  defp convert_response_amounts(resp) do
    new_breakdown = Enum.map(resp["breakdown"], fn
      %{"taxCode" => "CD", "amount" => amount} = item ->
        new_amount = parse_scientific_notation(amount)
        Map.put(item, "amount", new_amount)
      other_item ->
        other_item
    end)

    Logger.info("IPS UPDATED AMOUNT IN BREAKDOWN: #{inspect(new_breakdown)}")

    updated_resp = Map.put(resp, "breakdown", new_breakdown)
    {:ok, updated_resp}
  end

  defp parse_scientific_notation(amount) do
    case Decimal.parse(to_string(amount)) do
      {decimal, _} -> Decimal.to_integer(decimal)
      :error -> amount
    end
  end

  @doc """
  Sends a request to the ZRA API.

  ## Parameters
    * payload - Encrypted request payload

  ## Returns
    * `{:ok, result}` on success
    * `{:error, reason}` on failure
  """
  def request(payload) do
    url = "https://ips-dev.zra.org.zm/ips"
    start_time = System.system_time(:millisecond)
    request_id = generate_request_id()

    # Determine service type and ID from payload
    {service_type, service_id} = extract_service_info(payload)

    IO.inspect(payload, label: "====== Request =====", limit: :infinity)
    headers = %{"Content-Type" => "application/json"}
    options = [
      timeout: 100_000,
      recv_timeout: 100_000,
      hackney: [:insecure]
    ]

    # Create initial log entry
    log_params = %{
      service_type: service_type,
      service_id: service_id,
      request_type: "ZRA_API",
      request_id: request_id,
      request_url: url,
      request_method: "POST",
      request_headers: headers,
      request_body: %{payload: payload},
      status: "PENDING"
    }

    {:ok, log_entry} = create_log_entry(log_params)

    IO.inspect payload, label: "============== PAYLOAD ============="

    case HTTPoison.post(url, payload, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} = response ->
        update_log_success(log_entry, response, start_time)
        handle_successful_response(body)

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} = response ->
        error_message = "Failed with status code: #{status_code}"
        update_log_error(log_entry, response, error_message, start_time)
        handle_error_response(status_code, body)

      {:error, %HTTPoison.Error{reason: reason}} = error ->
        error_message = "ZRA API Error: #{inspect(reason)}"
        update_log_error(log_entry, error, error_message, start_time)
        Logger.error(error_message)
        {:error, "A Proxy Exception Occurred: #{reason}"}
    end
  end

  def handle_successful_response(body) do
    case ZraEncoder.decrypt(body) do
      {:ok, resp} -> {:ok, resp}
      {:error, reason} -> {:error, reason}
    end
  end

  def handle_error_response(400, body), do: {:error, decode_error_response(body)}
  def handle_error_response(404, _), do: {:error, "A Proxy Exception Occurred: Resource not found"}
  def handle_error_response(500, body), do: {:error, decode_error_response(body)}
  def handle_error_response(401, _), do: {:error, "A Proxy Exception Occurred: Authentication failed"}
  def handle_error_response(status_code, body) do
    Logger.error("ZRA API Error (#{status_code}): #{inspect(body)}")
    {:error, "A Proxy Exception Occurred: Unexpected status code #{status_code}"}
  end

  defp decode_error_response(body) do
    case ZraEncoder.decrypt(body) do
      {:ok, nil} ->
        case Poison.decode(body) do
          {:ok, decoded} ->
            header = AtomicMap.convert(decoded, %{safe: false}).header
            %{code: header.status_code, description: header.status_description}
          {:error, _} ->
            "Unable to decode error response"
        end
      {:ok, decoded} ->
        decoded
      {:error, _} ->
        body
    end
  end

  # ============ Logging Helper Functions ============

  defp create_log_entry(params) do
    %ServiceLogs{}
    |> ServiceLogs.changeset(params)
    |> Repo.insert()
  end

  defp update_log_success(log_entry, response, start_time) do
    duration = System.system_time(:millisecond) - start_time

    log_entry
    |> ServiceLogs.changeset(%{
      response_code: response.status_code,
      response_body: %{body: response.body},
      duration_ms: duration,
      status: "SUCCESS"
    })
    |> Repo.update()
  end

  defp update_log_error(log_entry, response, error_message, start_time) do
    duration = System.system_time(:millisecond) - start_time

    response_body = case response do
      %HTTPoison.Response{body: body} when is_binary(body) ->
        case Poison.decode(body) do
          {:ok, decoded} -> decoded
          {:error, _} -> %{raw: body}
        end
      %HTTPoison.Error{reason: reason} ->
        %{error: reason}
      _ ->
        inspect(response)
    end

    response_code = case response do
      %HTTPoison.Response{status_code: code} -> code
      _ -> 500
    end

    log_entry
    |> ServiceLogs.changeset(%{
      response_code: response_code,
      response_body: response_body,
      duration_ms: duration,
      status: "ERROR",
      error_message: error_message
    })
    |> Repo.update()
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16()
    |> String.downcase()
  end

  defp extract_service_info(payload) do
    # Try to decode the payload to extract service info
    case Poison.decode(payload) do
      {:ok, decoded} ->
        case decoded do
          %{"service" => service, "req" => req} ->
            service_id = extract_service_id(service, req)
            {"ZRA", service_id}
          _ ->
            {"ZRA", "UNKNOWN"}
        end
      {:error, _} ->
        # If we can't decode the payload, use a default
        {"ZRA", "UNKNOWN"}
    end
  end

  defp extract_service_id("GET_PENDING_PRNS", %{"tpin" => tpin}) when not is_nil(tpin), do: tpin
  defp extract_service_id("GET_PRN_DETAILS", %{"prn" => prn}) when not is_nil(prn), do: prn
  defp extract_service_id(_, _), do: "UNKNOWN"
end
