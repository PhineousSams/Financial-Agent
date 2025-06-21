defmodule FinancialAgent.Workers.Helpers.ApiAuth do

  alias FinancialAgent.Repo
  alias FinancialAgent.Settings
  alias FinancialAgent.Settings.ApiIntegrator


  @duration 1_000_000 # 1 day

  def authenticate(params, client_ip \\ nil) do
    %{integrator_id: integrator_id, password: password} = params

    case Settings.get_integrator_by_integrator_id(integrator_id) do
      nil ->
        {:error, "Invalid Service API credentials"} |> respond()

      %ApiIntegrator{status: "ACTIVE"} = integrator ->
        authenticate_active_integrator(integrator, password, client_ip)

      _integrator ->
        {:error, "Integrator is not active"} |> respond()
    end
  end

  # Handle authentication for active integrators
  defp authenticate_active_integrator(integrator, password, client_ip) do
    with :ok <- validate_client_ip(integrator, client_ip),
         :ok <- validate_client_port(integrator, client_ip),
         true <- verify_password(integrator, password) do

      generate_and_update_token(integrator)
    else
      {:error, message} ->
        {:error, message} |> respond()

      false ->
        Settings.increment_attempt_count(integrator)
        {:error, "Invalid API credentials"} |> respond()
    end
  end

  # Validate client IP against integrator's allowed IP (if restricted)
  defp validate_client_ip(integrator, nil), do: :ok
  defp validate_client_ip(integrator, client_ip) do
    if integrator.ip_address && integrator.ip_address != "" && client_ip != integrator.ip_address do
      {:error, "IP address not authorized"}
    else
      :ok
    end
  end

  # Validate client port against integrator's allowed port (if restricted)
  defp validate_client_port(integrator, nil), do: :ok
  defp validate_client_port(integrator, client_ip) do
    if integrator.port && integrator.port != nil do
      port_str = to_string(integrator.port)
      client_port = extract_port_from_ip(client_ip)

      if client_port && client_port != port_str do
        {:error, "Port not authorized"}
      else
        :ok
      end
    else
      :ok
    end
  end

  # Verify the integrator password
  defp verify_password(integrator, password) do
    Settings.verify_integrator_password(integrator, password)
  end

  # Generate and update token in integrator record
  defp generate_and_update_token(integrator) do
    claims = extra_claims(integrator)
    token = generate_token(claims)
    expires_at = DateTime.add(DateTime.utc_now(), @duration, :second)

    case update_integrator_token(integrator, token, expires_at) do
      {:ok, updated_integrator} -> {:ok, token} |> respond(updated_integrator)
      {:error, _changeset} -> {:error, "Failed to generate token"} |> respond()
    end
  end

  defp extra_claims(integrator) do
    # Currently, no extra claims are generated
    %{}
  end

  # Private function to generate a token
  defp generate_token(claims) do
    # Generate and sign a token with the provided claims
    FinancialAgent.Token.generate_and_sign!(claims)
  end

  def invalidate(token) do
    case get_integrator_by_token(token) do
      nil ->
        %{
          "message" => "Token not found",
          "status" => false,
          "data" => %{
            "integrator" => %{},
            "auth" => %{}
          }
        }

      integrator ->
        update_integrator_token(integrator, nil, nil)

        %{
          "message" => "Token invalidated",
          "status" => true,
          "data" => %{
            "integrator" => %{},
            "auth" => %{}
          }
        }
    end
  end

  def token_valid?(integrator) do
    now = DateTime.utc_now()
    if DateTime.compare(now, integrator.expires_at) == :lt && integrator.status == "ACTIVE" do
      true
    else
      false
    end
  end

  def refresh_token(token) do
    case get_integrator_by_token(token) do
      nil ->
        respond({:error, "Invalid token"})

      integrator ->
        if token_valid?(integrator) do
          claims = extra_claims(integrator)
          new_token = generate_token(claims)
          expires_at = DateTime.add(DateTime.utc_now(), @duration, :second)

          case update_integrator_token(integrator, new_token, expires_at) do
            {:ok, updated_integrator} ->
              respond({:ok, new_token}, updated_integrator)

            {:error, _changeset} ->
              respond({:error, "Failed to refresh token"})
          end
        else
          respond({:error, "Token expired"})
        end
    end
  end

  def verify_token(token, client_ip \\ nil) do
    case get_integrator_by_token(token) do
      nil ->
        {:error, "Invalid token"}

      integrator ->
        cond do
          not token_valid?(integrator) ->
            {:error, "Token expired"}

          client_ip && integrator.ip_address && integrator.ip_address != "" && client_ip != integrator.ip_address ->
            {:error, "IP address not authorized"}

          client_ip && integrator.port && integrator.port != nil ->
            # If port is specified, check if it matches the expected port
            port_str = to_string(integrator.port)
            client_port = extract_port_from_ip(client_ip)

            if client_port && client_port != port_str do
              {:error, "Port not authorized"}
            else
              {:ok, integrator}
            end

          true ->
            {:ok, integrator}
        end
    end
  end

  # ========== work in progress ==========
  defp update_integrator_token(integrator, token, expires_at) do
    Settings.update_integrator(integrator, %{
      auth_token: token,
      expires_at: expires_at
    })
  end

  defp get_integrator_by_token(token) do
    Settings.get_integrator_by_token(token)
  end

  defp respond({:error, error_info}, _integrator \\ %{}) do
    %{
      "message" => error_info,
      "status" => false,
      "data" => %{}
    }
  end

  defp respond({:ok, token_info}, integrator) do
    %{
      "message" => "success",
      "status" => true,
      "data" => %{
        "access_token" => token_info,
        "expires_at" => DateTime.to_iso8601(integrator.expires_at)
      }
    }
  end

  # Extract port from IP address if it's in the format "ip:port"
  defp extract_port_from_ip(ip) when is_binary(ip) do
    case String.split(ip, ":", parts: 2) do
      [_, port] -> port
      _ -> nil
    end
  end
  defp extract_port_from_ip(_), do: nil
end
