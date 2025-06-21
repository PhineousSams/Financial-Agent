defmodule FinincialAgentWeb.ConfigsLive.ConfigsLiveFilterComponent do
  use FinincialAgentWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="modal-body">
      <.modal
        class="max-w-4xl p-2"
        id="configs-filter"
        show
        on_cancel={JS.patch(~p"/Admin/Configs/management")}
      >
        <form class="dataTables_filter" phx-submit="filter">
          <div class="modal-header">
            <h5 class="modal-title flex items-center text-lg font-semibold text-gray-700 my-2">
              <%= @page %>
            </h5>
          </div>

          <div class="modal-body">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <div>
                <div class="form-group space-y-3">
                  <label for="name" class="block text-sm font-medium text-gray-700">Name</label>
                  <input
                    type="search"
                    class="mt-1 block w-full p-2 border border-gray-300 rounded-md shadow-sm focus:ring-teal-500 focus:border-teal-500 sm:text-sm"
                    value={@params["filter"]["name"]}
                    name="name"
                    placeholder="Settings Name"
                    aria-describedby="basic-addon3"
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="modal-footer flex justify-start">
            <button
              type="submit"
              phx_disable_with="filtering..."
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white gradient-bg  focus:outline-none focus:ring-2 focus:ring-offset-2  my-2"
            >
              <i class="fal fa-filter mr-2"></i> Filter
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
