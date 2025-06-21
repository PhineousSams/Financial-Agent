defmodule FinincialToolWeb.CardComponents do
  use Phoenix.Component

  def card(assigns) do
    ~H"""
    <div class="bg-white shadow-md rounded-lg overflow-hidden">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def card_header(assigns) do
    ~H"""
    <div class="px-6 py-4 border-b border-gray-200">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def card_content(assigns) do
    ~H"""
    <div class="px-6 py-4">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def card_footer(assigns) do
    ~H"""
    <div class="px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-between">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def card_title(assigns) do
    ~H"""
    <h2 class="text-xl font-semibold text-gray-800">
      <%= render_slot(@inner_block) %>
    </h2>
    """
  end

  def card_description(assigns) do
    ~H"""
    <p class="mt-1 text-sm text-gray-600">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  def input_group(assigns) do
    ~H"""
    <div class="space-y-2">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  # def label(assigns) do
  #   ~H"""
  #   <label for={@for} class="block text-sm font-medium text-gray-700">
  #     <%= render_slot(@inner_block) %>
  #   </label>
  #   """
  # end

  # def input(assigns) do
  #   ~H"""
  #   <input
  #     type={@type}
  #     id={@id}
  #     name={@name}
  #     value={@value}
  #     class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
  #   />
  #   """
  # end

  def select(assigns) do
    ~H"""
    <select
      id={@id}
      name={@name}
      class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
    >
      <%= for {label, value} <- @options do %>
        <option value={value} selected={value == @value}><%= label %></option>
      <% end %>
    </select>
    """
  end

  def textarea(assigns) do
    ~H"""
    <textarea
      id={@id}
      name={@name}
      class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
      rows="3"
    ><%= render_slot(@inner_block) %></textarea>
    """
  end

  #    <%= if assigns[:readonly], do: "readonly" %>
  def button_card(assigns) do
    ~H"""
    <button
      class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      disabled={assigns[:disabled]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def icon(assigns) do
    ~H"""
    <svg
      class={@class}
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 20 20"
      fill="currentColor"
      aria-hidden="true"
    >
      <%= case @name do %>
        <% "hero-arrow-left-solid" -> %>
          <path
            fill-rule="evenodd"
            d="M9.707 14.707a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 1.414L7.414 9H15a1 1 0 110 2H7.414l2.293 2.293a1 1 0 010 1.414z"
            clip-rule="evenodd"
          />
        <% "hero-arrow-right-solid" -> %>
          <path
            fill-rule="evenodd"
            d="M10.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L12.586 11H5a1 1 0 110-2h7.586l-2.293-2.293a1 1 0 010-1.414z"
            clip-rule="evenodd"
          />
        <% "hero-document-plus" -> %>
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m3.75 9v6m3-3H9m1.5-12H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"
          />
      <% end %>
    </svg>
    """
  end

  def live_file_input_card(assigns) do
    ~H"""
    <div
      phx-drop-target={@upload.ref}
      class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md"
    >
      <div class="space-y-1 text-center">
        <svg
          class="mx-auto h-12 w-12 text-gray-400"
          stroke="currentColor"
          fill="none"
          viewBox="0 0 48 48"
          aria-hidden="true"
        >
          <path
            d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </svg>

        <div class="flex text-sm text-gray-600">
          <label
            for={@upload.ref}
            class="relative cursor-pointer bg-white rounded-md font-medium text-indigo-600 hover:text-indigo-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-indigo-500"
          >
            <span>Upload a file</span> <.live_file_input upload={@upload} class="sr-only" />
          </label>

          <p class="pl-1">or drag and drop</p>
        </div>

        <p class="text-xs text-gray-500">
          PNG, JPG, GIF up to 10MB
        </p>
      </div>
    </div>
    """
  end
end
