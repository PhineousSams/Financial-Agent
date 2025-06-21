defmodule FinancialAgent.Workers.Jobs.NFSTest do
  require Logger


  # FinancialAgent.Workers.Jobs.NFSTest.datetime(:seven)
  def datetime(:seven),
    do: Timex.format!(Timex.local() |> Timex.shift(hours: -2), new_date() <> "{h24}{m}{s}")

  def datetime(:twelve), do: Timex.format!(Timex.local(), new_date() <> "{h24}{m}{s}")

  def new_date() do
    %{month: m, day: d} = Timex.local()

    cond do
      m < 10 && d < 10 ->
        "{YY}{0M}{0D}"

      d < 10 ->
        "{YY}{M}{0D}"

      m < 10 ->
        "{YY}{0M}{D}"

      true ->
        "{YY}{M}{D}"
    end
  end

  def head_opts() do
    %{
      options: [
        hackney: [:insecure],
        timeout: 50_000,
        recv_timeout: 60_000,
        ssl: [versions: [:"tlsv1.2"], verify: :verify_none]
      ],
      headers: [hackney: [:insecure], timeout: 50_000, recv_timeout: 60_000]
    }
  end

  # FinancialAgent.Workers.Jobs.NFSTest.perform(10)
  def perform(times) do
    url = "https://102.23.122.222:8090/emoney/outward/transfer/v1"
    try do
      results =
        1..times
        |> Enum.map(fn iteration ->
          request_uuid = UUID.uuid4()
          Logger.debug("Making request #{iteration} of #{times} to #{url} with UUID: #{request_uuid}")
          current_second = DateTime.utc_now().second

          payload = %{
            "amount" => "#{current_second}.00",
            "from_acc" => "000231260974994432",
            # "to_acc" => "000238912345679",
            "to_acc" => "0002370313201562021",
            "cur_code" => "0967",
            "name" => "PHINEOUS SAMAKAYI"
          }

          token = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJzbWFydGxpbmsiLCJleHAiOjE3MzA1NTQyNDAsImlhdCI6MTczMDQ2Nzg0MCwiaXNzIjoic21hcnRsaW5rIiwianRpIjoiMDRhZDlkMmEtNWMxMi00MjEwLTllOWYtNzcxMDY0ZWFlY2VhIiwibmJmIjoxNzMwNDY3ODM5LCJzdWIiOiIxIiwidHlwIjoiYWNjZXNzIn0.58EADCPoOkTZ1iaqCSNkhJr9qlRZfMAyFAM5BmmGSQrZu0Vjy8beC-a8zjrYZVJ071pVyKMECr9KcSOMmMrGEg"
          headers = [
            {"x-request-id", request_uuid},
            {"Authorization", "Bearer #{token}"},
            {"Content-Type", "application/json"}
          ]

          Logger.info("Starting endpoint test for #{url} with #{times} iterations")

          options = head_opts().options

          case HTTPoison.post(url, Jason.encode!(payload), headers, options) do
            {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
              %{
                iteration: iteration,
                request_id: request_uuid,
                status_code: status_code,
                body: body,
                amount: "#{current_second}.00",
                success: status_code in 200..299
              }

            {:error, %HTTPoison.Error{reason: reason}} ->
              %{
                iteration: iteration,
                request_id: request_uuid,
                error: reason,
                amount: "#{current_second}.00",
                success: false
              }
          end
        end)

      successful_calls = Enum.count(results, & &1.success)
      Logger.info("Completed endpoint test. #{successful_calls}/#{times} successful calls")

      {:ok, results}
    rescue
      e ->
        Logger.error("Error testing endpoint: #{inspect(e)}")
        {:error, "Failed to complete endpoint test: #{inspect(e)}"}
    end
  end

  @doc """
  Makes HTTP POST requests to the specified endpoint a given number of times in parallel.

  ## Parameters
    - times: Integer representing how many times to call the endpoint
    - opts: Optional keyword list of options (e.g. max_concurrency)

  ## Returns
    - {:ok, results} on success where results is a list of response maps
    - {:error, reason} on failure
  """
  def call_endpoint_async(times, opts \\ []) when is_integer(times) and times > 0 do
    url = "https://102.23.122.222:8090/emoney/outward/transfer/v1"
    token = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJzbWFydGxpbmsiLCJleHAiOjE3MzAwMzMyMzMsImlhdCI6MTcyOTk0NjgzMywiaXNzIjoic21hcnRsaW5rIiwianRpIjoiMDY3YzQ2OWItM2NmZi00ZDY2LWI3MDctZGFhNjM1YzhlZjkzIiwibmJmIjoxNzI5OTQ2ODMyLCJzdWIiOiIxIiwidHlwIjoiYWNjZXNzIn0.r9VwQLBFVrqa7spYe8wLoydLFZLIAFft_bhOb2A5Vfe9o-AN4mJvw8NiH1Z2TwDcKIGXTY9qseFY-fV1m5oSsA"
    max_concurrency = Keyword.get(opts, :max_concurrency, 10)

    Logger.info("Starting async endpoint test for #{url} with #{times} iterations")

    try do
      results =
        1..times
        |> Task.async_stream(
          fn iteration ->
            # Generate a unique UUID for each async request
            request_uuid = UUID.uuid4()
            Logger.debug("Making async request #{iteration} of #{times} to #{url} with UUID: #{request_uuid}")

            headers = [
              {"x-request-id", request_uuid},
              {"Authorization", "Bearer #{token}"},
              {"Content-Type", "application/json"}
            ]

            # Get current second for the amount
            current_second = DateTime.utc_now().second

            payload = %{
              "amount" => "#{current_second}.00",
              "from_acc" => "000231260974994432",
              "to_acc" => "000238912345679",
              "cur_code" => "0967",
              "name" => "PHINEOUS SAMAKAYI"
            }

            case HTTPoison.post(url, Jason.encode!(payload), headers, recv_timeout: 30_000) do
              {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
                %{
                  iteration: iteration,
                  request_id: request_uuid,
                  status_code: status_code,
                  body: body,
                  amount: "#{current_second}.00",
                  success: status_code in 200..299
                }

              {:error, %HTTPoison.Error{reason: reason}} ->
                %{
                  iteration: iteration,
                  request_id: request_uuid,
                  error: reason,
                  amount: "#{current_second}.00",
                  success: false
                }
            end
          end,
          max_concurrency: max_concurrency,
          ordered: true
        )
        |> Enum.map(fn {:ok, result} -> result end)

      successful_calls = Enum.count(results, & &1.success)
      Logger.info("Completed async endpoint test. #{successful_calls}/#{times} successful calls")

      {:ok, results}
    rescue
      e ->
        Logger.error("Error testing endpoint asynchronously: #{inspect(e)}")
        {:error, "Failed to complete async endpoint test: #{inspect(e)}"}
    end
  end
end
