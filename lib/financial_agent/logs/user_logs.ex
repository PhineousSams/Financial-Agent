defmodule FinincialTool.Logs.UserLogs do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_user_logs" do
    field :activity, :string
    field :pre_data, :map
    field :post_data, :map
    field :action, :string
    belongs_to :user, FinincialTool.Accounts.User, foreign_key: :user_id, type: :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_logs, attrs) do
    user_logs
    |> cast(attrs, [:activity, :user_id, :pre_data, :post_data, :action])
    |> validate_required([:activity, :user_id])
  end
end
