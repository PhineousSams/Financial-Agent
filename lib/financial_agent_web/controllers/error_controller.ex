defmodule FinancialAgentWeb.ErrorController do
  use FinancialAgentWeb, :controller

  @doc """
  Handles requests to invalid endpoints.
  Returns a standardized error response for any HTTP method.
  """
  def invalid_endpoint(conn, _params) do
    conn
    |> put_status(:not_found)
    |> json(%{
      data: %{
        service_status: "FAILED",
        message: "Invalid endpoint. The requested resource does not exist.",
        body: nil
      }
    })
  end
end
