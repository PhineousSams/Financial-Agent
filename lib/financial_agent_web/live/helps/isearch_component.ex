defmodule FinincialToolWeb.Helps.ISearchComponent do
  @moduledoc false
  use FinincialToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mb-3 flex items-center justify-start">
      <form phx-change="iSearch" class="flex items-center space-x-2">
        <div class="relative">
          <input
            type="search"
            class="form-input block w-full pl-10 pr-3 py-2 rounded border border-gray-300 rounded-lg shadow-sm focus:outline-none focus:ring-1 focus:ring-green-500"
            value={@params["filter"]["isearch"]}
            name="isearch"
            placeholder="Search"
            aria-describedby="basic-addon3"
          />
          <span
            class="absolute inset-y-0 left-0 flex items-center bg-blue-600 px-2 rounded-left text-white"
            id="basic-addon3"
          >

            <Heroicons.magnifying_glass outline  class="h-5 w-5"/>
          </span>
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

  #  @impl true
  #  def handle_event("iSearch", params, socket)do
  #    live_patch "iSearch", to: "?"<>querystring params
  #    {:noreply, socket}
  #  end
end
