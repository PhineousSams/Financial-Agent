defmodule FinancialAgent.Logs.ApiLogs do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_api_logs" do
    field :ref_id, :string
    field :api_key, :string
    field :endpoint, :string
    field :request_method, :string
    field :request_path, :string
    field :request_params, :map
    field :response_status, :integer
    field :response_body, :map
    field :processing_time_ms, :integer
    field :ip_address, :string
    field :user_agent, :string
    field :error_details, :map
    field :service_type, :string
    field :service_id, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(api_log, attrs) do
    api_log
    |> cast(attrs, [:ref_id, :api_key, :endpoint, :request_method, :request_path, :request_params,
                    :response_status, :response_body, :processing_time_ms, :ip_address,
                    :user_agent, :error_details, :service_type, :service_id])
    |> validate_required([:endpoint, :request_method, :request_path])
  end

end
