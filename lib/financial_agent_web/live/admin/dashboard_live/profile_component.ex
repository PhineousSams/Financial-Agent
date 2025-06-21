defmodule FinincialToolWeb.DashboardLive.ProfileComponent do
  use FinincialToolWeb, :live_component

  @impl true
  def update(%{user: user} = assigns, socket) do
    IO.inspect(user)

    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center  justify-center bg-gray-800 bg-opacity-60">
      <div class="bg-white rounded-lg shadow-lg w-full max-w-3xl">
        <!-- Modal Header -->
        <div class="flex items-center justify-between p-4 border-b border-gray-200">
          <h5 class="text-lg font-semibold text-primary flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="w-6 h-6 mr-2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M17.982 18.725A7.488 7.488 0 0 0 12 15.75a7.488 7.488 0 0 0-5.982 2.975m11.963 0a9 9 0 1 0-11.963 0m11.963 0A8.966 8.966 0 0 1 12 21a8.966 8.966 0 0 1-5.982-2.275M15 9.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
              />
            </svg>
            My Profile
          </h5>

          <.link
            patch={@patch}
            class="text-gray-500 hover:text-gray-700"
            data-dismiss="modal"
            aria-label="Close"
          >
            <svg
              class="w-6 h-6"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </.link>
        </div>
        <!-- Modal Body -->
        <div class="p-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- User Information -->
            <div class="space-y-2">
              <h5 class="text-lg font-semibold text-gray-700">User Information</h5>

              <p class="text-gray-600">Username: <%= @user.username %></p>

              <p class="text-gray-600">First Name: <%= @user.first_name %></p>

              <p class="text-gray-600">Last Name: <%= @user.last_name %></p>
            </div>
            <!-- Contact Details -->
            <div class="space-y-2">
              <h5 class="text-lg font-semibold text-gray-700">Contact Details</h5>

              <p class="text-gray-600">Email: <%= @user.email %></p>

              <p class="text-gray-600">Phone: <%= @user.phone %></p>

              <p class="text-gray-600">Address: <%= @user.address %></p>
            </div>
          </div>
          <!-- Additional Details -->
          <div class="mt-4">
            <h5 class="text-lg font-semibold text-gray-700">Additional Details</h5>

            <p class="text-gray-600">ID Number: <%= @user.id_no %></p>

            <p class="text-gray-600">Date of Birth: <%= @user.dob %></p>

            <p class="text-gray-600">Sex: <%= @user.sex %></p>

            <p class="text-gray-600">Role: <%= @user.user_type %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
