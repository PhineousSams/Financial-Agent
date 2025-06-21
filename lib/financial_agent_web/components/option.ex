defmodule Option do
  use Phoenix.Component

  def bordered(assigns) do
    ~H"""
    <div
      x-data="{
        optionMenuOpen: false,
        optionMenuCloseDelay: 200,
        optionMenuCloseTimeout: null,
        optionMenuLeave() {
            let that = this;
            this.optionMenuCloseTimeout = setTimeout(() => {
                that.optionMenuClose();
            }, this.optionMenuCloseDelay);
        },
        optionMenuClose(){
            this.optionMenuOpen = false;
        }
      }"
      class=" relative inline-block text-left"
    >
      <div>
        <button
          @click="optionMenuOpen = ! optionMenuOpen;"
          @keydown.escape.window="optionMenuLeave()"
          type="button"
          class="inline-flex w-full justify-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          id="menu-button"
          aria-expanded="true"
          aria-haspopup="true"
        >
          Options
          <svg
            x-bind:class="{ '-rotate-180' : optionMenuOpen==true }"
            class="relative top-[1px] ml-1 h-3 w-3 ease-out duration-300"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <polyline points="6 9 12 15 18 9"></polyline>
          </svg>
        </button>
      </div>

      <div
        x-cloak
        x-ref="optionDropdown"
        x-show="optionMenuOpen"
        @click.outside="optionMenuLeave()"
        x-transition:enter="transition ease-out duration-300"
        x-transition:enter-start="transform opacity-0 scale-95"
        x-transition:enter-end="transform opacity-100 scale-100"
        x-transition:leave="transition ease-in duration-300"
        x-transition:leave-start="transform opacity-100 scale-100"
        x-transition:leave-end="transform opacity-0 scale-95"
        class="absolute right-0 z-30 mt-2 w-56 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
        role="menu"
        aria-orientation="vertical"
        aria-labelledby="menu-button"
        tabindex="-1"
      >
        <div class="py-1" role="none">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  def accordion(assigns) do
    ~H"""
    <div class="rounded-lg border border-neutral-200 bg-white" x-data="{accordion: false}">
      <h2 class="mb-0" id={"heading#{@title}"}>
        <button
          class="group relative flex w-full items-center rounded-t-[15px] border-0 bg-white px-5 py-4 text-left text-base text-neutral-800 transition [overflow-anchor:none] hover:z-[2] focus:z-[3] focus:outline-none [&:not([data-te-collapse-collapsed])]:bg-white [&:not([data-te-collapse-collapsed])]:text-primary [&:not([data-te-collapse-collapsed])]:[box-shadow:inset_0_-1px_0_rgba(229,231,235)]"
          type="button"
          @click="accordion = ! accordion;"
          aria-expanded="true"
          aria-controls="collapseOne"
        >
          <%= @title %>
          <span class="ml-auto h-5 w-5 shrink-0 fill-[#336dec] transition-transform duration-200 ease-in-out group-[[data-te-collapse-collapsed]]:rotate-0 group-[[data-te-collapse-collapsed]]:fill-[#212529] motion-reduce:transition-none">
            <template x-if="accordion">
              <svg
                class="relative top-[1px] ml-1 h-3 w-3 rotate-180 ease-out duration-300"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <polyline points="6 9 12 15 18 9"></polyline>
              </svg>
            </template>

            <template x-if="!accordion">
              <svg
                class="relative top-[1px] ml-1 h-3 w-3 ease-out duration-300"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <polyline points="6 9 12 15 18 9"></polyline>
              </svg>
            </template>
          </span>
        </button>
      </h2>

      <div
        x-cloak
        x-show="accordion"
        x-transition:enter="transform transition ease-in-out duration-500 sm:duration-700"
        x-transition:enter-start="translate-x-full"
        x-transition:enter-end="translate-x-0"
        x-transition:leave="transform transition ease-in-out duration-500 sm:duration-700"
        x-transition:leave-start="translate-x-0"
        x-transition:leave-end="translate-x-full"
        aria-labelledby={@title}
      >
        <div class="px-5 py-4">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <Option.bordered_default permissions={@permissions} status={@status}>
      </Option.bordered_default>
  """
  attr :permissions, :list, required: true
  attr :record, :map, required: true
  attr :delete, :boolean, default: false
  attr :show_details, :boolean, default: false
  attr :permission_name, :string, required: true
  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def bordered_default(assigns) do
    ~H"""
    <.bordered>
      <%= if @record.status != 4 do %>
        <%= if @record.status == 1 do %>
          <%= if Enum.member?(@permissions, "#{@permission_name}-modify") do %>
            <.item phx-click="edit_record" phx-value-id={@record.id} label="Edit" />
          <% end %>

          <%= if Enum.member?(@permissions, "#{@permission_name}-modify") do %>
            <.item
              phx-click="status"
              phx-value-status="0"
              phx-click="status"
              phx-value-id={@record.id}
              label="Deactivate"
              class="text-rose-700 hover:bg-gray-100 hover:text-rose-900"
            />
          <% end %>
          <%= render_slot(@inner_block) %>
        <% end %>

        <%= if @record.status == 0 do %>
          <%= if Enum.member?(@permissions, "#{@permission_name}-modify") do %>
            <.item
              phx-click="status"
              phx-value-status="1"
              phx-value-id={@record.id}
              label="Activate"
              class="text-green-700 hover:bg-gray-100 hover:text-gray-900"
            />
            <%= if @delete do %>
              <.item label="Delete" phx-value-id={@record.id} phx-click="delete" />
            <% end %>
          <% end %>

          <%= if Enum.member?(@permissions, "#{@permission_name}-delete") do %>
            <.item
              phx-click="delete"
              phx-value-status="5"
              phx-click="status"
              phx-value-id={@record.id}
              label="Delete"
              class="text-rose-700 hover:bg-gray-100 hover:text-rose-900"
            />
          <% end %>
        <% end %>
      <% else %>
        <%= if @show_details do %>
          <.item
            label="Show Details"
            phx-value-id={@record.id}
            phx-click="show_modal"
            class="text-gray-700 hover:bg-gray-100 hover:text-gray-900"
          />
        <% end %>

        <%= if Enum.member?(@permissions, "#{@permission_name}-approve") do %>
          <.item
            phx-value-status="1"
            phx-click="approve_record"
            phx-value-id={@record.id}
            label="Approve"
            class="text-green-700 hover:bg-gray-100 hover:text-gray-900"
          />
        <% end %>

        <%= if Enum.member?(@permissions, "#{@permission_name}-reject") do %>
          <.item
            phx-value-status="6"
            phx-click="reject_record"
            phx-value-id={@record.id}
            label="Reject"
            class="text-rose-700 hover:bg-gray-100 hover:text-rose-900"
          />
        <% end %>

        <%= if !Enum.member?(@permissions, "#{@permission_name}-approve") and !Enum.member?(@permissions, "#{@permission_name}-reject") do %>
          <div class="text-center text-rose-500">No Actions</div>
        <% end %>
      <% end %>

      <%= if @record.status == 6 do %>
        <%= if Enum.member?(@permissions, "#{@permission_name}-modify") do %>
          <.item phx-click="edit_record" phx-value-id={@record.id} label="Edit" />
        <% end %>
      <% end %>
    </.bordered>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <Option.item label="Edit" />
  """
  attr :label, :string, required: true
  attr :class, :string, default: "text-gray-700 hover:bg-gray-100 hover:text-gray-900"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  def item(assigns) do
    ~H"""
    <div
      {@rest}
      x-on:click="optionMenuOpen = ! optionMenuOpen"
      class={"w-full text-left block px-4 py-2 text-sm #{@class}"}
    >
      <%= @label %>
    </div>
    """
  end
end
