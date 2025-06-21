defmodule FinancialAgent.Workers.Integration.NapsaService do
  use PipeTo.Override

  alias FinancialAgent.Repo
  alias FinancialAgent.Logs.ServiceLogs


  @base_url "http://127.0.0.1:7000"
  # @base_url "https://api.icare.napsa.gov.zm"
  @request_options [
    timeout: 100_000,
    recv_timeout: 100_000,
    hackney: [:insecure]
  ]

  def authenticate(username, password) do
    req = %{
      username: username,
      password: password
    }

    "#{@base_url}/central-authentication-integrations/auth/authenticate"
    |> make_request(:post, req, %{"Content-Type" => "application/json"})
  end

  def get_npin_details(npin, token) do
    "#{@base_url}/icare-thirdparty/npinDetails/#{npin}"
    |> make_authenticated_request(:get, nil, token)
  end

  def payment_confirmation(params, token) do
    # Remove token from params before sending to API
    params_without_token = Map.drop(params, ["token"])

    "#{@base_url}/icare-thirdparty/paymentConfirmation"
    |> make_authenticated_request(:post, params_without_token, token)
  end

  def eod_report(params, token) do
    # Remove token from params before sending to API
    params_without_token = Map.drop(params, ["token"])

    "#{@base_url}/icare-thirdparty/eodReports"
    |> make_authenticated_request(:post, params_without_token, token)
  end

  def bank_statement(statement_header, transaction_entries, token) do
    req = %{
      statementHeader: statement_header,
      transactionEntries: transaction_entries
    }

    "#{@base_url}/icare-thirdparty/bankStatement"
    |> make_authenticated_request(:post, req, token)
  end

  # Generic request handler
  defp make_request(url, method, body \\ nil, headers \\ %{}) do
    encoded_body = if body, do: Poison.encode!(body), else: ""
    start_time = System.system_time(:millisecond)
    request_id = generate_request_id()

    # Determine service type and ID from URL
    {service_type, service_id} = extract_service_info(url, body)

    # Create initial log entry
    log_params = %{
      service_type: service_type,
      service_id: service_id,
      request_type: get_request_type(url),
      request_id: request_id,
      request_url: url,
      request_method: to_string(method),
      request_headers: headers,
      request_body: body,
      status: "PENDING"
    }

    {:ok, log_entry} = create_log_entry(log_params)

    request_fn = case method do
      :get -> &HTTPoison.get/3
      :post -> &HTTPoison.post/4
    end

    case apply(request_fn, build_request_args(method, url, encoded_body, headers)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        IO.inspect response_body, label: "====== Response Body ====="
        decoded_body = Poison.decode!(response_body)
        update_log_success(log_entry, %{status_code: 200, body: decoded_body}, start_time)
        {:ok, decoded_body}

      {:ok, %HTTPoison.Response{status_code: 400, body: response_body}} ->
        error_resp = prep_error_resp(response_body)
        update_log_error(log_entry, %{status_code: 400, body: error_resp}, "Bad request", start_time)
        {:error, error_resp}

      {:ok, %HTTPoison.Response{status_code: 401, body: response_body}} ->
        error_message = "Authentication failed: #{response_body}"
        update_log_error(log_entry, %{status_code: 401, body: response_body}, error_message, start_time)
        {:error, error_message}

      {:ok, %HTTPoison.Response{status_code: 404, body: response_body}} ->
        error_message = "Resource not found"
        update_log_error(log_entry, %{status_code: 404, body: response_body}, error_message, start_time)
        {:error, error_message}

      {:ok, %HTTPoison.Response{status_code: 500, body: response_body}} ->
        error_resp = prep_error_resp(response_body)
        update_log_error(log_entry, %{status_code: 500, body: error_resp}, "Server error", start_time)
        {:error, error_resp}

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason, label: "====== Response Error =====", limit: :infinity)
        error_message = "Exception occurred: #{reason}"
        update_log_error(log_entry, %{reason: reason}, error_message, start_time)
        {:error, error_message}

      {:ok, response} ->
        IO.inspect(response, label: "====== Unexpected Response =====", limit: :infinity)
        error_message = "Unexpected response"
        update_log_error(log_entry, response, error_message, start_time)
        {:error, error_message}
    end
  end

  # Build request arguments based on HTTP method
  defp build_request_args(:get, url, _body, headers) do
    [url, headers, @request_options]
  end

  defp build_request_args(:post, url, body, headers) do
    [url, body, headers, @request_options]
  end

  # Helper for authenticated requests with client-provided token
  defp make_authenticated_request(url, method, body \\ nil, token) do
    headers = %{
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{token}"
    }

    make_request(url, method, body, headers)
  end

  defp prep_error_resp(body) do
    case Poison.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> body
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
      response_body: response.body,
      duration_ms: duration,
      status: "SUCCESS"
    })
    |> Repo.update()
  end

  defp update_log_error(log_entry, response, error_message, start_time) do
    duration = System.system_time(:millisecond) - start_time

    response_body = case response do
      %{body: body} when is_map(body) -> body
      %{body: body} when is_binary(body) ->
        case Poison.decode(body) do
          {:ok, decoded} -> decoded
          {:error, _} -> %{raw: body}
        end
      _ -> inspect(response)
    end

    response_code = case response do
      %{status_code: code} -> code
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

  defp extract_service_info(url, body) do
    cond do
      String.contains?(url, "npinDetails") ->
        # Extract NPIN from URL
        npin = url |> String.split("/") |> List.last()
        {"NAPSA", npin}

      String.contains?(url, "paymentConfirmation") and is_map(body) ->
        # Extract payment reference from body
        payment_ref = body["paymentReference"] || body["icarePaymentReference"] || "UNKNOWN"
        {"NAPSA", payment_ref}

      String.contains?(url, "eodReports") and is_map(body) ->
        # Extract batch reference from body
        batch_ref = body["batchReferenceNumber"] || "UNKNOWN"
        {"NAPSA", batch_ref}

      String.contains?(url, "bankStatement") ->
        # Use a generic ID for bank statements
        {"NAPSA", "BANK_STATEMENT"}

      String.contains?(url, "authenticate") ->
        # Use a generic ID for authentication
        {"NAPSA", "AUTH"}

      true ->
        # Default case
        {"NAPSA", "UNKNOWN"}
    end
  end

  defp get_request_type(url) do
    cond do
      String.contains?(url, "npinDetails") -> "GET_NPIN_DETAILS"
      String.contains?(url, "paymentConfirmation") -> "PAYMENT_CONFIRMATION"
      String.contains?(url, "eodReports") -> "EOD_REPORT"
      String.contains?(url, "bankStatement") -> "BANK_STATEMENT"
      String.contains?(url, "authenticate") -> "AUTHENTICATE"
      true -> "UNKNOWN"
    end
  end
end
