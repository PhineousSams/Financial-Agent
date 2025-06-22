import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# Load .env file in development and test environments
if config_env() in [:dev, :test] and File.exists?(".env") do
  File.read!(".env")
  |> String.split("\n")
  |> Enum.each(fn line ->
    case String.split(line, "=", parts: 2) do
      [key, value] when key != "" ->
        key = String.trim(key)
        if not String.starts_with?(key, "#") do
          System.put_env(key, String.trim(value))
        end
      _ -> :ok
    end
  end)
end

# Configure OAuth for all environments
if System.get_env("GOOGLE_CLIENT_ID") do
  config :ueberauth, Ueberauth.Strategy.Google.OAuth,
    client_id: System.get_env("GOOGLE_CLIENT_ID"),
    client_secret: System.get_env("GOOGLE_CLIENT_SECRET")
end

# Configure HubSpot OAuth
if System.get_env("HUBSPOT_CLIENT_ID") do
  config :ueberauth, Ueberauth.Strategy.HubSpot.OAuth,
    client_id: System.get_env("HUBSPOT_CLIENT_ID"),
    client_secret: System.get_env("HUBSPOT_CLIENT_SECRET")
end

# Configure OpenAI for all environments
if System.get_env("OPENAI_API_KEY") do
  config :openai,
    api_key: System.get_env("OPENAI_API_KEY"),
    organization_key: System.get_env("OPENAI_ORGANIZATION_KEY"),
    http_options: [recv_timeout: 60_000]
end

# Configure Guardian for all environments
if System.get_env("GUARDIAN_SECRET_KEY") do
  config :financial_agent, FinancialAgent.Guardian,
    issuer: "financial_agent",
    secret_key: System.get_env("GUARDIAN_SECRET_KEY"),
    ttl: {30, :days}
end

# Configure email settings
if System.get_env("SMTP_HOST") do
  config :financial_agent, FinancialAgent.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: System.get_env("SMTP_HOST"),
    port: String.to_integer(System.get_env("SMTP_PORT") || "587"),
    username: System.get_env("SMTP_USERNAME"),
    password: System.get_env("SMTP_PASSWORD"),
    tls: :always,
    auth: :always,
    retries: 2
end

# Configure Mailgun if preferred
if System.get_env("MAILGUN_API_KEY") do
  config :financial_agent, FinancialAgent.Mailer,
    adapter: Swoosh.Adapters.Mailgun,
    api_key: System.get_env("MAILGUN_API_KEY"),
    domain: System.get_env("MAILGUN_DOMAIN")
end

# Configure SendGrid if preferred
if System.get_env("SENDGRID_API_KEY") do
  config :financial_agent, FinancialAgent.Mailer,
    adapter: Swoosh.Adapters.Sendgrid,
    api_key: System.get_env("SENDGRID_API_KEY")
end

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/financial_agent start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :financial_agent, FinancialAgentWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :financial_agent, FinancialAgent.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "9000")

  config :financial_agent, FinancialAgentWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port,
      # Production HTTP settings
      compress: true,
      protocol_options: [
        idle_timeout: 60_000,
        request_timeout: 30_000
      ]
    ],
    secret_key_base: secret_key_base,
    # LiveView signing salt for security
    live_view: [
      signing_salt: System.get_env("LIVE_VIEW_SIGNING_SALT") || secret_key_base
    ],
    # Session configuration
    session: [
      store: :cookie,
      key: "_financial_agent_key",
      signing_salt: System.get_env("SESSION_SIGNING_SALT") || secret_key_base,
      same_site: "Lax",
      secure: true,
      http_only: true,
      max_age: 86400 * 30  # 30 days
    ]

  # Configure additional production database settings
  maybe_ssl = if System.get_env("DATABASE_URL") && String.contains?(System.get_env("DATABASE_URL"), "sslmode=require") do
    [
      # ssl: true,
      # ssl_opts: [
      #   verify: :verify_none,
      #   versions: [:"tlsv1.2", :"tlsv1.3"]
      # ]
    ]
  else
    []
  end

  config :financial_agent, FinancialAgent.Repo,
    [
      url: database_url,
      pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
      socket_options: maybe_ipv6,
      # Connection timeouts
      timeout: 15_000,
      ownership_timeout: 20_000,
      # Queue settings
      queue_target: 5_000,
      queue_interval: 10_000,
      # Enable prepared statements
      prepare: :named,
      # Log slow queries
      log: String.to_atom(System.get_env("DB_LOG_LEVEL") || "false")
    ] ++ maybe_ssl

  # Configure production logging
  if System.get_env("LOG_LEVEL") do
    config :logger, level: String.to_atom(System.get_env("LOG_LEVEL"))
  end

  # Configure Sentry for error tracking (if using)
  if System.get_env("SENTRY_DSN") do
    config :sentry,
      dsn: System.get_env("SENTRY_DSN"),
      environment_name: System.get_env("SENTRY_ENV") || "production",
      enable_source_code_context: true,
      root_source_code_paths: [File.cwd!()],
      tags: %{
        env: "production"
      },
      included_environments: ["production"]
  end

  # Configure Redis for caching (if using)
  if System.get_env("REDIS_URL") do
    config :financial_agent, FinancialAgent.Cache,
      adapter: Nebulex.Adapters.Redis,
      url: System.get_env("REDIS_URL")
  end

  # Configure rate limiting
  if System.get_env("ENABLE_RATE_LIMITING") == "true" do
    config :hammer,
      backend: {
        Hammer.Backend.Redis,
        [
          expiry_ms: 60_000 * 60 * 2,
          redis_url: System.get_env("REDIS_URL") || "redis://localhost:6379/1"
        ]
      }
  end

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :financial_agent, FinancialAgentWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :financial_agent, FinancialAgentWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :financial_agent, FinancialAgent.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
