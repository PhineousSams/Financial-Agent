defmodule FinincialToolWeb.UserLive.BlockedFilterComponent do
  use FinincialToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="modal-body">
      <.modal id="blocked-filter-modal" show on_cancel={JS.patch(~p"/Admin/admin/users/blocked")}>
        <form class="space-y-4 p-4" phx-submit="filter">
          <div class="modal-header gradient-bg text-white p-4 rounded-lg flex items-center justify-center">
            <h5 class="text-xl font-semibold flex items-center space-x-2">
              <i class="subheader-icon fal fa-filter"></i> <span><%= @page %></span>
            </h5>
          </div>

          <div class="modal-body p-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="form-group">
                <label for="first_name" class="block text-sm font-medium text-gray-700">
                  First Name
                </label>
                <input
                  type="search"
                  class="form-input mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-green-600  focus:ring-green-600"
                  value={@params["filter"]["first_name"]}
                  name="first_name"
                  placeholder="First Name"
                  aria-describedby="basic-addon3"
                />
              </div>

              <div class="form-group">
                <label for="last_name" class="block text-sm font-medium text-gray-700">
                  Last Name
                </label>
                <input
                  type="search"
                  class="form-input mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-green-600  focus:ring-green-600"
                  value={@params["filter"]["last_name"]}
                  name="last_name"
                  placeholder="Last Name"
                  aria-describedby="basic-addon3"
                />
              </div>

              <div class="form-group">
                <label for="username" class="block text-sm font-medium text-gray-700">Username</label>
                <input
                  type="search"
                  class="form-input mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-green-600  focus:ring-green-600"
                  value={@params["filter"]["username"]}
                  name="username"
                  placeholder="Username"
                  aria-describedby="basic-addon3"
                />
              </div>

              <div class="form-group">
                <label for="phone" class="block text-sm font-medium text-gray-700">Phone</label>
                <input
                  type="search"
                  class="form-input mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-green-600  focus:ring-green-600"
                  value={@params["filter"]["phone"]}
                  name="phone"
                  placeholder="Phone"
                  aria-describedby="basic-addon3"
                />
              </div>

              <div class="form-group">
                <label for="email" class="block text-sm font-medium text-gray-700">Email</label>
                <input
                  type="search"
                  class="form-input mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-green-600  focus:ring-green-600"
                  value={@params["filter"]["email"]}
                  name="email"
                  placeholder="Email"
                  aria-describedby="basic-addon3"
                />
              </div>

              <div class="form-group">
                <label for="sex" class="block text-sm font-medium text-gray-700">Sex</label>
                <select
                  class="form-select mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-green-600  focus:ring-green-600"
                  name="sex"
                >
                  <option value="" selected aria-describedby="basic-addon3"></option>

                  <option value={@params["filter"]["F"]} aria-describedby="basic-addon3">F</option>

                  <option value={@params["filter"]["M"]} aria-describedby="basic-addon3">M</option>
                </select>
              </div>

              <div class="form-group">
                <label for="name" class="block text-sm font-medium text-gray-700">User Role</label>
                <select
                  name="name"
                  id="name"
                  class="form-select mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-green-600  focus:ring-green-600"
                >
                  <option value="" selected>-- Role --</option>

                  <%= for role <- @roles do %>
                    <option phx-value-role={role.name}><%= role.name %></option>
                  <% end %>
                </select>
              </div>
            </div>
          </div>

          <div class="modal-footer flex justify-start p-4">
            <button
              type="submit"
              phx_disable_with="filtering..."
              class="px-2 py-2 gradient-bg text-white rounded-md shadow-sm hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-offset-2  focus:ring-green-600"
            >
              <i class="fal fa-filter"></i> Filter
            </button>
          </div>
        </form>
      </.modal>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
