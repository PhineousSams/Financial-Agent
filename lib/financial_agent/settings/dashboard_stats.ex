defmodule FinincialAgent.Settings.DashboardStats do
  use Ecto.Schema
  import Ecto.Changeset

  @fields ~w(id name value inserted_at)a

  @derive {Jason.Encoder, only: @fields}
  schema "tbl_dashboard_stats" do
    field :name, :string
    field :value, :string

    timestamps()
  end

  @doc false
  def changeset(dashboard_stats, attrs) do
    dashboard_stats
    |> cast(attrs, @fields)
    |> validate_required([:name, :value])
  end
end
