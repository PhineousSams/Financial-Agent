defmodule FinancialAgent.Notifications.Email do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_email" do
    field :attempts, :string
    field :mail_body, :string
    field :recipient_email, :string
    field :sender_email, :string
    field :sender_name, :string
    field :status, :string
    field :subject, :string

    timestamps()
  end

  @doc false
  def changeset(email, attrs) do
    email
    |> cast(attrs, [
      :subject,
      :sender_email,
      :sender_name,
      :mail_body,
      :recipient_email,
      :status,
      :attempts
    ])
    |> validate_required([
      :subject,
      :sender_email,
      :sender_name,
      :mail_body,
      :recipient_email,
      :status
    ])
  end
end
