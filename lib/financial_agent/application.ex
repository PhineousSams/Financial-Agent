defmodule FinincialAgent.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      FinincialAgentWeb.Telemetry,
      # Start the Ecto repository
      FinincialAgent.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: FinincialAgent.PubSub},
      {Cachex, name: :store},
      # Start Oban for background jobs
      {Oban, Application.fetch_env!(:financial_agent, Oban)},
      # Start Finch
      {Finch, name: FinincialAgent.Finch},
      # Start the Endpoint (http/https)
      FinincialAgentWeb.Endpoint
      # Start a worker by calling: FinincialAgent.Worker.start_link(arg)
      # {FinincialAgent.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FinincialAgent.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FinincialAgentWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
