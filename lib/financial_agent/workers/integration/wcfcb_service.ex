defmodule FinancialAgent.Workers.Integration.WcfcbService do
  use PipeTo.Override

  alias FinancialAgent.Repo
  alias FinancialAgent.Logs.ServiceLogs

  @base_url "http://127.0.0.1:4000"
  # @base_url "https://api.wcfcb.gov.zm" # Production URL would go here
  @request_options [
    timeout: 100_000,
    recv_timeout: 100_000,
    hackney: [:insecure]
  ]

  # 1.1 Login
  def login(provider_code, password) do
    req = %{
      providerCode: provider_code,
      password: password
    }

    "#{@base_url}/auth/login"
    |> make_request(:post, req, %{"Content-Type" => "application/json"})
  end

  # 1.2 Refresh Token
  def refresh_token(refresh_token) do
    req = %{
      refreshToken: refresh_token
    }

    "#{@base_url}/auth/refreshToken"
    |> make_request(:post, req, %{"Content-Type" => "application/json"})
  end

  # 2.1 Get Employer Details
  def get_employer_details(employer_number, token) do
    "#{@base_url}/api/v1/employer/getEmployerDetails/#{employer_number}"
    |> make_authenticated_request(:get, nil, token)
  end

  # 2.2 Get Employer Balance
  def get_employer_balance(employer_number, token) do
    "#{@base_url}/api/v1/employer/getEmployerBalance/#{employer_number}"
    |> make_authenticated_request(:get, nil, token)
  end

  # 3.1 Process Payment
  def process_payment(params, token) do
    "#{@base_url}/api/v1/employer/processPayment"
    |> make_authenticated_request(:post, params, token)
  end

  # 3.2 Reprocess Payment
  def reprocess_payment(transaction_reference, token) do
    "#{@base_url}/api/v1/employer/reprocessPayment/#{transaction_reference}"
    |> make_authenticated_request(:post, nil, token)
  end

  # 3.3 Check Payment Status
  def check_payment_status(transaction_reference, token) do
    "#{@base_url}/api/v1/employer/checkPaymentStatus/#{transaction_reference}"
    |> make_authenticated_request(:get, nil, token)
  end

  # 4.1 Bank Statement Upload
  def bank_statement_upload(params, token) do
    "#{@base_url}/api/v1/bankStatement"
    |> make_authenticated_request(:post, params, token)
  end

  # 4.2 EOD Report Upload
  def eod_report_upload(params, token) do
    "#{@base_url}/api/v1/eodReport"
    |> make_authenticated_request(:post, params, token)
  end

  # 5.1 Get Payment Channels
  def get_payment_channels(token) do
    "#{@base_url}/api/v1/paymentChannel"
    |> make_authenticated_request(:get, nil, token)
  end

  # Generic request handler
  defp make_request(url, method, body \\ nil, headers \\ %{}) do
    encoded_body = if body, do: Poison.encode!(body), else: ""
    start_time = System.system_time(:millisecond)
    request_id = generate_request_id()

    # Determine service type and ID from URL and body
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
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} = response ->
        IO.inspect response_body, label: "====== Response Body ====="
        decoded_body = Poison.decode!(response_body)
        update_log_success(log_entry, response, start_time)
        {:ok, decoded_body}

      {:ok, %HTTPoison.Response{status_code: 400, body: response_body}} = response ->
        error_resp = prep_error_resp(response_body)
        update_log_error(log_entry, response, "Bad request", start_time)
        {:error, error_resp}

      {:ok, %HTTPoison.Response{status_code: 401, body: response_body}} = response ->
        error_message = "Authentication failed: #{response_body}"
        update_log_error(log_entry, response, error_message, start_time)
        {:error, error_message}

      {:ok, %HTTPoison.Response{status_code: 404, body: response_body}} = response ->
        error_message = "Resource not found"
        update_log_error(log_entry, response, error_message, start_time)
        {:error, error_message}

      {:ok, %HTTPoison.Response{status_code: 500, body: response_body}} = response ->
        error_resp = prep_error_resp(response_body)
        update_log_error(log_entry, response, "Server error", start_time)
        {:error, error_resp}

      {:error, %HTTPoison.Error{reason: reason}} = error ->
        IO.inspect(reason, label: "====== Response Error =====", limit: :infinity)
        error_message = "Exception occurred: #{reason}"
        update_log_error(log_entry, error, error_message, start_time)
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

  defp extract_service_info(url, body) do
    cond do
      String.contains?(url, "/auth/login") ->
        # Extract provider code from body if available
        provider_code = if is_map(body) and Map.has_key?(body, :providerCode), do: body.providerCode, else: "UNKNOWN"
        {"WCFCB", provider_code}

      String.contains?(url, "/auth/refreshToken") ->
        # Use a generic ID for refresh token
        {"WCFCB", "REFRESH_TOKEN"}

      String.contains?(url, "getEmployerDetails") ->
        # Extract employer number from URL
        employer_number = url |> String.split("/") |> List.last()
        {"WCFCB", employer_number}

      String.contains?(url, "getEmployerBalance") ->
        # Extract employer number from URL
        employer_number = url |> String.split("/") |> List.last()
        {"WCFCB", employer_number}

      String.contains?(url, "processPayment") and is_map(body) ->
        # Extract transaction reference from body if available
        transaction_ref = if is_map(body) and Map.has_key?(body, :transactionReference), do: body.transactionReference, else: "UNKNOWN"
        {"WCFCB", transaction_ref}

      String.contains?(url, "reprocessPayment") ->
        # Extract transaction reference from URL
        transaction_ref = url |> String.split("/") |> List.last()
        {"WCFCB", transaction_ref}

      String.contains?(url, "checkPaymentStatus") ->
        # Extract transaction reference from URL
        transaction_ref = url |> String.split("/") |> List.last()
        {"WCFCB", transaction_ref}

      String.contains?(url, "bankStatement") ->
        # Use a generic ID for bank statements
        {"WCFCB", "BANK_STATEMENT"}

      String.contains?(url, "eodReport") ->
        # Use a generic ID for EOD reports
        {"WCFCB", "EOD_REPORT"}

      String.contains?(url, "paymentChannel") ->
        # Use a generic ID for payment channels
        {"WCFCB", "PAYMENT_CHANNELS"}

      true ->
        # Default case
        {"WCFCB", "UNKNOWN"}
    end
  end

  defp get_request_type(url) do
    cond do
      String.contains?(url, "/auth/login") -> "LOGIN"
      String.contains?(url, "/auth/refreshToken") -> "REFRESH_TOKEN"
      String.contains?(url, "getEmployerDetails") -> "GET_EMPLOYER_DETAILS"
      String.contains?(url, "getEmployerBalance") -> "GET_EMPLOYER_BALANCE"
      String.contains?(url, "processPayment") -> "PROCESS_PAYMENT"
      String.contains?(url, "reprocessPayment") -> "REPROCESS_PAYMENT"
      String.contains?(url, "checkPaymentStatus") -> "CHECK_PAYMENT_STATUS"
      String.contains?(url, "bankStatement") -> "BANK_STATEMENT"
      String.contains?(url, "eodReport") -> "EOD_REPORT"
      String.contains?(url, "paymentChannel") -> "GET_PAYMENT_CHANNELS"
      true -> "UNKNOWN"
    end
  end
end
