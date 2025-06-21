defmodule FinincialTool.Notifications.Alerts do
  use Ecto.Schema
  import Ecto.Changeset
  use Endon

  schema "tbl_alert" do
    field :alert_type, :string
    field :approved_by_id, :integer
    field :created_by_id, :integer
    field :description, :string
    field :message, :string
    field :status, :string, default: "PENDING_APPROVAL"

    timestamps()
  end

  @doc false
  def changeset(alerts, attrs) do
    alerts
    |> cast(attrs, [:alert_type, :description, :message, :status, :created_by_id, :approved_by_id])
    |> validate_required([:alert_type, :message, :status])
  end

  def update_changeset(alerts, attrs, _opts \\ []) do
    alerts
    |> cast(attrs, [:alert_type, :description, :message, :status, :created_by_id, :approved_by_id])
  end
end
