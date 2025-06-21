defmodule FinancialAgent.Settings.Receivers do
  use Ecto.Schema
  import Ecto.Changeset

  alias FinancialAgent.Accounts.User

  @derive {Jason.Encoder, only: [:name, :email, :status, :company, :maker_id, :updated_by]}
  schema "tbl_notification_receivers" do
    field :name, :string
    field :email, :string
    field :status, :string
    field :company, :string

    belongs_to :maker, User, foreign_key: :maker_id, type: :id
    belongs_to :checker, User, foreign_key: :updated_by, type: :id
    timestamps()
  end

  @doc false
  def changeset(receivers, attrs) do
    receivers
    |> cast(attrs, [:name, :email, :status, :company, :maker_id, :updated_by])
    |> validate_required([:name, :email, :company])
  end
end
