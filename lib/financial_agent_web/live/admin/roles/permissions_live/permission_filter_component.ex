defmodule FinincialToolWeb.PermissionsLive.PermissionsLiveFilterComponent do
  use FinincialToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="">
      <form class="" phx-submit="filter">
        <div class="modal-header">
          <h5 class="modal-title">
            <i class="subheader-icon fal fa-filter"><%= @page %></i>
          </h5>
        </div>

        <div class="modal-body">
          <div class="row form-group grid grid-cols-2 gap-4">
            <div class="col-md-6">
              <div class="form-group">
                <label for="name" class="form-label block text-sm font-medium text-gray-700">
                  Name
                </label>

                <input
                  type="search"
                  class="form-control mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  value={@params["filter"]["name"]}
                  name="name"
                  placeholder="Permission Name"
                  aria-describedby="basic-addon3"
                />
              </div>
            </div>

            <div class="col-md-6">
              <div class="form-group">
                <label for="description" class="form-label block text-sm font-medium text-gray-700">
                  Section
                </label>

                <input
                  type="search"
                  class="form-control mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  value={@params["filter"]["description"]}
                  name="description"
                  placeholder="Permission Description"
                  aria-describedby="basic-addon3"
                />
              </div>
            </div>

            <div class="col-md-6">
              <div class="form-group">
                <label for="group_name" class="form-label block text-sm font-medium text-gray-700">
                  Group Name
                </label>

                <input
                  type="search"
                  class="form-control mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  value={@params["filter"]["group_name"]}
                  name="group_name"
                  placeholder="Group Name"
                  aria-describedby="basic-addon3"
                />
              </div>
            </div>

            <div class="col-md-6">
              <div class="form-group">
                <label for="section_name" class="form-label block text-sm font-medium text-gray-700">
                  Section Name
                </label>

                <input
                  type="search"
                  class="form-control mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  value={@params["filter"]["section_name"]}
                  name="Section Name"
                  placeholder="Value Type"
                  aria-describedby="basic-addon3"
                />
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer flex justify-end">
          <button
            type="submit"
            phx_disable_with="filtering..."
            class="btn btn-info submit bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
          >
            <i class="fal fa-filter"></i> Filter
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
