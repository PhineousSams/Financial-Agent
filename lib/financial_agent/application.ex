defmodule FinancialAgent.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      FinancialAgentWeb.Telemetry,
      # Start the Ecto repository
      FinancialAgent.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: FinancialAgent.PubSub},
      {Cachex, name: :store},
      # Start Oban for background jobs
      {Oban, Application.fetch_env!(:financial_agent, Oban)},
      # Start Finch
      {Finch, name: FinancialAgent.Finch},
      # Start the Endpoint (http/https)
      FinancialAgentWeb.Endpoint
      # Start a worker by calling: FinancialAgent.Worker.start_link(arg)
      # {FinancialAgent.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FinancialAgent.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FinancialAgentWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
