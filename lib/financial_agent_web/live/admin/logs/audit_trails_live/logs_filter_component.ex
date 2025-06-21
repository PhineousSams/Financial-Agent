defmodule FinincialAgentWeb.LogsLive.LogsFilterComponent do
  use FinincialAgentWeb, :live_component

  def render(assigns) do
    ~H"""
    <div
      class="modal fade show"
      id="modal-report"
      tabindex="-1"
      role="dialog"
      aria-hidden="true"
      style="display: block; padding-right: 17px;"
    >
      <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h4 class="modal-title">
              Filter Logs
            </h4>

            <button type="button" class="close" phx-click="close" phx-target={@myself}>
              <span aria-hidden="true"><i class="fal fa-times"></i></span>
            </button>
          </div>

          <div class="modal-body">
            <form id="filter-form" phx-submit="filter" phx-target={@myself}>
              <div class="form-group">
                <label for="log_type">Log Type</label>
                <select name="log_type" id="log_type" class="form-control">
                  <option value="">All</option>

                  <%= for type <- @log_types do %>
                    <option value={type}><%= type %></option>
                  <% end %>
                </select>
              </div>

              <div class="form-group">
                <label for="username">Username</label>
                <input
                  type="text"
                  name="username"
                  id="username"
                  class="form-control"
                  placeholder="Enter username"
                />
              </div>

              <div class="form-group">
                <label for="start_date">Start Date</label>
                <input type="date" name="start_date" id="start_date" class="form-control" />
              </div>

              <div class="form-group">
                <label for="end_date">End Date</label>
                <input type="date" name="end_date" id="end_date" class="form-control" />
              </div>
              <button type="submit" class="btn btn-primary">Apply Filter</button>
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("filter", params, socket) do
    send(self(), {:apply_filter, params})
    {:noreply, push_patch(socket, to: ~p"/admin/logs?#{params}")}
  end

  def handle_event("close", _, socket) do
    send(self(), :close_modal)
    {:noreply, socket}
  end
end
