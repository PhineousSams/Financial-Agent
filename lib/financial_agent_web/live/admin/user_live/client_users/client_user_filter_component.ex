defmodule FinincialAgentWeb.ClientUserLive.ClientUserLiveFilterComponent do
  use FinincialAgentWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="modal-body">
      <.modal
        class="max-w-4xl p-2"
        id="client-filter-modal"
        show
        on_cancel={JS.patch(~p"/Admin/Client/users/management")}
      >
        <form class="space-y-4 p-4" phx-submit="filter">
          <div class="modal-header gradient-bg text-white flex items-center justify-center p-4 rounded-t-lg">
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
                  class="form-input mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
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
                  class="form-input mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
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
                  class="form-input mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
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
                  class="form-input mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
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
                  class="form-input mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  value={@params["filter"]["email"]}
                  name="email"
                  placeholder="Email"
                  aria-describedby="basic-addon3"
                />
              </div>

              <div class="form-group">
                <label for="sex" class="block text-sm font-medium text-gray-700">Sex</label>
                <select
                  class="form-select mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  name="sex"
                >
                  <option value="" selected aria-describedby="basic-addon3"></option>

                  <option value={@params["filter"]["F"]} aria-describedby="basic-addon3">F</option>

                  <option value={@params["filter"]["M"]} aria-describedby="basic-addon3">M</option>
                </select>
              </div>

              <div class="form-group">
                <label for="user_type" class="block text-sm font-medium text-gray-700">
                  User Type
                </label>
                <select
                  class="form-select mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  name="user_type"
                >
                  <option value="" selected aria-describedby="basic-addon3"></option>

                  <option value={@params["filter"]["EMPLOYER"]} aria-describedby="basic-addon3">
                    EMPLOYER
                  </option>

                  <option value={@params["filter"]["CLIENT"]} aria-describedby="basic-addon3">
                    CLIENT
                  </option>
                </select>
              </div>
            </div>
          </div>

          <div class="modal-footer flex justify-start p-4 border-t ">
            <button
              type="submit"
              phx_disable_with="filtering..."
              class="btn btn-info px-4 py-2 gradient-bg text-white rounded-md shadow-sm hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
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
