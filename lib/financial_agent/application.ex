defmodule FinincialTool.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      FinincialToolWeb.Telemetry,
      # Start the Ecto repository
      FinincialTool.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: FinincialTool.PubSub},
      {Cachex, name: :store},
      # Start Oban for background jobs
      {Oban, Application.fetch_env!(:financial_tool, Oban)},
      # Start Finch
      {Finch, name: FinincialTool.Finch},
      # Start the Endpoint (http/https)
      FinincialToolWeb.Endpoint
      # Start a worker by calling: FinincialTool.Worker.start_link(arg)
      # {FinincialTool.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FinincialTool.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FinincialToolWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
