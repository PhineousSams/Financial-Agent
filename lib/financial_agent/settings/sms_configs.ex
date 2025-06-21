defmodule FinincialAgent.Settings.SmsConfigs do
  use Endon
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_sms_configuration" do
    field :username, :string
    field :password, :string
    field :host, :string
    field :sender, :string
    field :max_attempts, :string
    field :status, :string

    timestamps()
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(attrs, [:username, :password, :host, :sender, :max_attempts, :status])
    |> validate_required([:username, :password, :host, :sender, :status])
  end
end
