defmodule FinincialTool.Logs.AuditLogs do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_audit_logs" do
    field :action, :string
    field :description, :string
    field :resource_type, :string
    field :resource_id, :id
    field :pre_data, :map
    field :post_data, :map
    field :metadata, :map

    belongs_to :user, FinincialTool.Accounts.User, foreign_key: :user_id, type: :id

    timestamps(inserted_at: :created_at, type: :utc_datetime)
  end

  @doc false
  def changeset(audit_trail, attrs) do
    audit_trail
    |> cast(attrs, [
      :action,
      :description,
      :resource_type,
      :resource_id,
      :pre_data,
      :post_data,
      :metadata,
      :user_id
    ])
    |> validate_required([
      :action,
      :description,
      :resource_type,
      :resource_id,
      :user_id
    ])
  end
end
