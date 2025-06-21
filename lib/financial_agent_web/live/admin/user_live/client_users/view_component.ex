defmodule FinancialAgentWeb.Admin.ClientUserLive.ViewComponent do
  @moduledoc false
  use FinancialAgentWeb, :live_component

  alias FinancialAgent.Roles
  alias FinancialAgent.Accounts

  @impl true

  def update(%{user: user, title: title, tbl_user: tbl_user} = assigns, socket) do
    changeset = Accounts.change_user(user)

    table = [
      %{head: "FIRST NAME:", value: tbl_user.first_name},
      %{head: "LAST NAME:", value: tbl_user.last_name},
      %{head: "USERNAME:", value: tbl_user.username},
      %{head: "EMAIL:", value: tbl_user.email},
      %{head: "GENDER:", value: tbl_user.sex},
      %{head: "DOB:", value: tbl_user.dob},
      %{head: "ID_No:", value: tbl_user.id_no},
      %{head: "PHONE:", value: tbl_user.phone},
      %{head: "ADDRESS:", value: tbl_user.address}
    ]

    {:ok,
     socket
     |> assign(assigns)
     |> assign(table: table)
     |> assign(:title, title)
     |> assign(:changeset, changeset)
     |> assign(:roles, Roles.list_user_roles())}
  end
end
