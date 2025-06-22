# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :financial_agent,
  ecto_repos: [FinancialAgent.Repo]

config :financial_agent, :base_url, "http://localhost:9000"

# OpenAI Configuration
config :openai,
  api_key: System.get_env("OPENAI_API_KEY"),
  organization_key: System.get_env("OPENAI_ORGANIZATION_KEY")

# OAuth Configuration
config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [
      default_scope: "email profile https://www.googleapis.com/auth/gmail.modify https://www.googleapis.com/auth/calendar"
    ]},
    hubspot: {FinancialAgentWeb.Auth.HubSpotStrategy, [
      site: "https://api.hubapi.com",
      authorize_url: "https://app.hubspot.com/oauth/authorize",
      token_url: "https://api.hubapi.com/oauth/v1/token",
      request_path: "/auth/hubspot",
      callback_path: "/auth/hubspot/callback",
      # default_scope: "oauth marketing-email sales-email-read transactional-email crm.objects.appointments.read crm.objects.appointments.write crm.objects.contacts.read crm.objects.contacts.write",
      default_scope: "oauth crm.objects.contacts.write crm.objects.appointments.read crm.objects.appointments.write marketing-email sales-email-read transactional-email crm.objects.contacts.read",
    ]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

# Oban Configuration for background jobs
config :financial_agent, Oban,
  repo: FinancialAgent.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [
    default: 10,
    gmail_sync: 5,
    calendar_sync: 5,
    hubspot_sync: 5,
    ai_processing: 3
  ]

# Guardian Configuration for JWT
config :financial_agent, FinancialAgent.Guardian,
  issuer: "financial_agent",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY") || "your-secret-key-here"

# Configures the endpoint
config :financial_agent, FinancialAgentWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: FinancialAgentWeb.ErrorHTML, json: FinancialAgentWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: FinancialAgent.PubSub,
  live_view: [signing_salt: "X0N15SJP"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :financial_agent, FinancialAgent.Mailer, adapter: Swoosh.Adapters.Local

config :joken, default_signer: "Jdvt/1XbL1ecis+x3e+lebqF4NFT9HH+yr7pWGQGbsx7TbOzVXZRgbwaauR8mLjh"

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs" 
