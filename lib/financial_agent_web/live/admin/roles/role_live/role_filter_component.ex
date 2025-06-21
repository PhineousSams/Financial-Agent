defmodule FinincialToolWeb.RoleLive.RoleLiveFilterComponent do
  use FinincialToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="p-6 bg-white rounded-lg shadow">
      <form class="space-y-6" phx-submit="filter">
        <div class="flex justify-between items-center">
          <h5 class="text-xl font-semibold text-gray-800 flex items-center">
            <i class="subheader-icon fal fa-filter text-gray-600 mr-2"></i><%= @page %>
          </h5>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label for="name" class="block text-sm font-medium text-gray-700">Name</label>
            <input
              type="search"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              value={@params["filter"]["name"]}
              name="name"
              placeholder="Permission Name"
              aria-describedby="basic-addon3"
            />
          </div>

          <div>
            <label for="description" class="block text-sm font-medium text-gray-700">Section</label>
            <input
              type="search"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              value={@params["filter"]["description"]}
              name="description"
              placeholder="Permission Description"
              aria-describedby="basic-addon3"
            />
          </div>
        </div>

        <div class="flex justify-end">
          <button
            type="submit"
            phx_disable_with="filtering..."
            class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            <i class="fal fa-filter mr-2"></i> Filter
          </button>
        </div>
      </form>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
