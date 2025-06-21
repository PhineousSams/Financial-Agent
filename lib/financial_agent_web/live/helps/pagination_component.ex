defmodule FinincialToolWeb.Helps.PaginationComponent do
  @moduledoc false
  use FinincialToolWeb, :live_component
  import FinincialToolWeb.Helps.DataTable

  @distance 5

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(pagination_assigns(assigns[:pagination_data]))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-between items-center py-4 px-3 text-xs">
      <div>
        <span>
          Showing <%= if @total_entries != 0, do: (@page_number - 1) * @page_size + 1, else: 0 %> to <%= if @page_number *
                                                                                                              @page_size >
                                                                                                              @total_entries,
                                                                                                            do:
                                                                                                              @total_entries,
                                                                                                            else:
                                                                                                              @page_number *
                                                                                                                @page_size %> of <%= @total_entries %> entries
        </span>
      </div>

      <div>
        <ul id={assigns[:id] || "pagination"} class="flex space-x-2">
          <%= if @total_pages > 1 do %>
            <li class="page-item">
              <%= prev_link(assigns, @params, @page_number) %>
            </li>

            <%= for num <- start_page(@page_number)..end_page(@page_number, @total_pages) do %>
              <li class={"page-item #{if @page_number == num, do: "whitespace-nowrap gradient-bg text-white"}"}>
                <.link
                  patch={"?" <> querystring(@params, page: num)}
                  class={"page-link px-3 py-1 rounded-sm #{if @page_number == num, do: "whitespace-nowrap gradient-bg text-white ", else: "bg-gray-200"}"}
                >
                  <%= num %>
                </.link>
              </li>
            <% end %>

            <li class="page-item">
              <%= next_link(assigns, @params, @page_number, @total_pages) %>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  defp pagination_assigns([]) do
    [
      page_number: 1,
      page_size: 10,
      total_entries: 0,
      total_pages: 0
    ]
  end

  defp pagination_assigns(%Scrivener.Page{} = pagination) do
    [
      page_number: pagination.page_number,
      page_size: pagination.page_size,
      total_entries: pagination.total_entries,
      total_pages: pagination.total_pages
    ]
  end

  def prev_link(assigns, conn, current_page) do
    if current_page != 1 do
      ~H"""
      <.link patch={"?" <> querystring(conn, page: current_page - 1)} class="page-link">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          class="flex-shrink-0 size-6 "
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
        </svg>
      </.link>
      """
    else
      ~H"""
      <.link patch="#" class="page-link btn-disabled">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          class="flex-shrink-0 size-6 "
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
        </svg>
      </.link>
      """
    end
  end

  def next_link(assigns, conn, current_page, num_pages) do
    if current_page != num_pages do
      ~H"""
      <.link patch={"?" <> querystring(conn, page: current_page + 1)} class="page-link">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          class="flex-shrink-0 size-6 "
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
        </svg>
      </.link>
      """
    else
      ~H"""
      <.link patch="#" class="page-link btn-disabled">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fwidth="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          class="flex-shrink-0 size-6 "
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
        </svg>
      </.link>
      """
    end
  end

  def start_page(current_page) when current_page - @distance <= 0, do: 1
  def start_page(current_page), do: current_page - @distance

  def end_page(current_page, 0), do: current_page

  def end_page(current_page, total)
      when current_page <= @distance and @distance * 2 <= total do
    @distance * 2
  end

  def end_page(current_page, total) when current_page + @distance >= total, do: total
  def end_page(current_page, _total), do: current_page + @distance - 1
end
