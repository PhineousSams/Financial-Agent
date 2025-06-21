defmodule FinincialToolWeb.UserLive.ViewComponent do
  @moduledoc false
  use FinincialToolWeb, :live_component

  alias FinincialTool.Roles
  alias FinincialTool.Accounts

  @impl true

  def update(%{user: user, title: title} = assigns, socket) do
    changeset = Accounts.change_user(user)

    table = [
      %{head: "FIRST NAME:", value: user.first_name},
      %{head: "LAST NAME:", value: user.last_name},
      %{head: "USERNAME:", value: user.username},
      %{head: "EMAIL:", value: user.email},
      %{head: "GENDER:", value: user.sex},
      %{head: "DOB:", value: user.dob},
      %{head: "ID_No:", value: user.id_no},
      %{head: "PHONE:", value: user.phone},
      %{head: "ADDRESS:", value: user.address}
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
