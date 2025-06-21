defmodule FinincialToolWeb.Plugs.AuthPlug do
  import Plug.Conn
  alias FinincialTool.Workers.Helpers.ApiAuth
  alias FinincialTool.Logs.ApiLogs
  alias FinincialTool.Repo

  def init(default), do: default

  def call(conn, _default) do
    IO.inspect conn, label: "============ conn ==========="

    # Extract token from authorization header or body params
    token = get_token(conn)

    # Start timing the request and create a reference ID for logging
    start_time = System.system_time(:millisecond)
    ref_id = generate_ref_id()

    if token do
      case ApiAuth.verify_token(token) do
        {:ok, integrator} ->
          if integrator.status == "ACTIVE" do
            conn |> put_status(:ok) |> assign(:integrator, integrator)
          else
            # Log inactive integrator
            log_auth_failure(conn, ref_id, start_time, "Integrator not Active", 403, integrator)
            conn
            |> put_status(:forbidden)
            |> Phoenix.Controller.put_view(FinincialToolWeb.ErrorView)
            |> Phoenix.Controller.json(%{
              "message" => "Integrator not Active",
              "status" => false,
              "data" => %{}
            })
            |> halt()
          end
        {:error, error_info} ->
          log_auth_failure(conn, ref_id, start_time, "Unauthorized API Access", 401, %{error: error_info})
          conn
          |> put_status(:unauthorized)
          |> Phoenix.Controller.put_view(FinincialToolWeb.ErrorView)
          |> Phoenix.Controller.json(%{
            "message" => "Unauthorized API Access",
            "status" => false,
            "data" => %{}
          })
          |> halt()
      end
    else
      # Log missing token
      log_auth_failure(conn, ref_id, start_time, "Access token is missing", 400, nil)
      conn
      |> put_status(:bad_request)
      |> Phoenix.Controller.put_view(FinincialToolWeb.ErrorView)
      |> Phoenix.Controller.json(%{
        "message" => "Access token is missing",
        "status" => false,
        "data" => %{}
      })
      |> halt()
    end
  end

  # Get token from authorization header first, then from body params
  defp get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> Map.get(conn.body_params, "access_token")
    end
  end

  # Log authentication failures using the same pattern as WcfcbController
  defp log_auth_failure(conn, ref_id, start_time, reason, status_code, details) do
    # Extract service type and ID from the request
    {_service_type, service_id} = extract_api_service_info(conn)

    # Calculate processing time
    end_time = System.system_time(:millisecond)
    processing_time = end_time - start_time

    # Create log entry
    log_params = %{
      ref_id: ref_id,
      api_key: get_api_key(conn),
      endpoint: conn.request_path,
      request_method: conn.method,
      request_path: conn.request_path,
      request_params: conn.params,
      ip_address: get_client_ip(conn),
      user_agent: get_user_agent(conn),
      service_type: "AUTH",
      service_id: service_id,
      response_status: status_code,
      response_body: %{
        data: %{
          service_status: "FAILED",
          message: reason,
          details: details
        }
      },
      processing_time_ms: processing_time
    }

    # Create the API log entry
    {:ok, _api_log} = create_api_log(log_params)
  end

  # Generate a unique reference ID for the API request
  defp generate_ref_id do
    "API-" <> (
      :crypto.strong_rand_bytes(8)
      |> Base.encode16(case: :upper)
    )
  end

  # Create a new API log entry
  defp create_api_log(params) do
    %ApiLogs{}
    |> ApiLogs.changeset(params)
    |> Repo.insert()
  end

  # Extract the API key from the request headers
  defp get_api_key(conn) do
    conn
    |> get_req_header("x-api-key")
    |> List.first()
  end

  # Extract the client IP address from the request
  defp get_client_ip(conn) do
    conn
    |> get_req_header("x-forwarded-for")
    |> List.first()
    || (conn.remote_ip |> :inet.ntoa() |> to_string())
  end

  # Extract the user agent from the request headers
  defp get_user_agent(conn) do
    conn
    |> get_req_header("user-agent")
    |> List.first()
  end

  # Extract service type and ID from the request
  defp extract_api_service_info(conn) do
    case conn.params do
      %{"service" => service, "payload" => %{"employerNumber" => employer_number}} when service in ["GET_EMPLOYER_DETAILS", "GET_EMPLOYER_BALANCE"] ->
        {service, employer_number}

      %{"service" => service, "payload" => %{"transactionReference" => transaction_ref}} when service in ["PROCESS_PAYMENT", "REPROCESS_PAYMENT", "PAYMENT_STATUS"] ->
        {service, transaction_ref}

      %{"service" => "BANK_STATEMENT", "payload" => %{"statementHeader" => %{"providerBankStatementId" => statement_id}}} ->
        {"BANK_STATEMENT", statement_id}

      %{"service" => "EOD_REPORT_UPLOAD", "payload" => %{"providerEodId" => eod_id}} ->
        {"EOD_REPORT_UPLOAD", eod_id}

      %{"service" => service} ->
        {service, "UNKNOWN"}

      _ ->
        {"AUTH", "UNKNOWN"}
    end
  end
end
