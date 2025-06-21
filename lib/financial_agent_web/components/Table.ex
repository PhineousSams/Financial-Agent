defmodule FinincialAgentWeb.Components.Custom.Table do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="min-w-full divide-y divide-gray-200 table">
        <thead class="bg-blue-600 text-white">
          <tr class="table-row">
            <th
              :for={col <- @col}
              class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider"
            >
              <%= col[:label] %>
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="table-row">
            <td
              :for={{col, _i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["px-6 py-4 whitespace-nowrap", @row_click && "hover:cursor-pointer"]}
            >
              <%= render_slot(col, @row_item.(row)) %>
            </td>
            <td class="px-6 py-4 whitespace-nowrap z-20">
              <div class="relative">
                <button
                  phx-click={JS.toggle(to: "#dropdown-menu-#{(@row_id && @row_id.(row)) || row.id}")}
                  class="bg-blue-600 hover:bg-blue-700 text-white px-2 py-1 rounded-md text-sm font-medium transition duration-150 ease-in-out"
                >
                  Options
                </button>
                <div
                  id={"dropdown-menu-#{@row_id && @row_id.(row) || row.id}"}
                  class="hidden absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg z-10"
                  phx-click-away={
                    JS.hide(to: "#dropdown-menu-#{(@row_id && @row_id.(row)) || row.id}")
                  }
                >
                  <%= render_slot(@action, @row_item.(row)) %>
                </div>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
