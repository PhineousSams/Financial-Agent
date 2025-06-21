defmodule FinincialTool.Logs.ServiceLogs do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_service_logs" do
    field :request_type,    :string
    field :request_id,      :string
    field :request_url,     :string
    field :request_method,  :string
    field :request_headers, :map
    field :request_body,    :map
    field :response_code,   :integer
    field :response_body,   :map
    field :duration_ms,     :integer
    field :status,         :string
    field :error_message,  :string
    field :metadata,       :map
    field :service_type, :string
    field :service_id, :string

    timestamps()
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [
         :request_type,
         :request_id,
         :request_url,
         :request_method,
         :request_headers,
         :request_body,
         :response_code,
         :response_body,
         :duration_ms,
         :status,
         :error_message,
         :metadata,
         :service_type,
         :service_id
       ])
    |> validate_required([
         :service_type,
         :service_id,
         :request_type,
         :request_id,
         :request_url,
         :request_method,
         :status
       ])
    |> unique_constraint(:request_id)
  end
end
