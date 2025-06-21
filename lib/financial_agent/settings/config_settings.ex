defmodule FinancialAgent.Settings.ConfigSettings do
  use Ecto.Schema
  import Ecto.Changeset

  use Endon

  @columns ~w(id name value value_type description updated_by inserted_at updated_at)a

  schema "tbl_config_settings" do
    field :name, :string
    field :value, :string
    field :value_type, :string
    field :description, :string
    field :deleted_at, :naive_datetime
    field :updated_by, :string

    timestamps()
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, @columns)
    |> validate_required([:name, :value, :value_type, :description])
  end

  def create_changeset(settings, attrs) do
    settings
    |> cast(attrs, [
      :name,
      :value,
      :value_type,
      :description,
      :updated_by,
      :deleted_at
    ])
  end
end
