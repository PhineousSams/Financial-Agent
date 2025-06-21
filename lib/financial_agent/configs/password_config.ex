defmodule FinincialTool.Configs.PasswordConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @columns ~w(id name min_characters max_characters repetitive_characters sequential_numeric maker_id updated_by
  reuse restriction max_attempts force_change min_special min_numeric min_lower_case min_upper_case)a

  schema "tbl_password_maintenance" do
    field :name, :string
    field :min_characters, :integer, default: 0
    field :max_characters, :integer, default: 0
    field :repetitive_characters, :integer, default: 0
    field :sequential_numeric, :integer, default: 0
    field :reuse, :integer, default: 0
    field :restriction, :boolean
    field :max_attempts, :integer, default: 0
    field :force_change, :integer, default: 0
    field :min_special, :integer, default: 0
    field :min_numeric, :integer, default: 0
    field :min_lower_case, :integer, default: 0
    field :min_upper_case, :integer, default: 0
    belongs_to :updater, Loans.Accounts.User, foreign_key: :updated_by, type: :id
    belongs_to :maker, Loans.Accounts.User, foreign_key: :maker_id, type: :id

    timestamps()
  end

  @doc false
  def changeset(password_config, attrs) do
    password_config
    |> cast(attrs, @columns)
    |> validate_required([
      :min_characters,
      :max_characters,
      :repetitive_characters,
      :sequential_numeric,
      :reuse,
      :restriction,
      :max_attempts,
      :force_change,
      :min_special,
      :min_numeric,
      :min_lower_case,
      :min_upper_case,
      :maker_id
    ])
  end
end
