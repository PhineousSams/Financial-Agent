import Config

# ──────────────────────────────
# ✅ Load .env for dev/test only
# ──────────────────────────────
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

# ──────────────────────────────
# ✅ OAuth / API keys for all envs
# ──────────────────────────────
if System.get_env("GOOGLE_CLIENT_ID") do
  config :ueberauth, Ueberauth.Strategy.Google.OAuth,
    client_id: System.get_env("GOOGLE_CLIENT_ID"),
    client_secret: System.get_env("GOOGLE_CLIENT_SECRET")
end

if System.get_env("HUBSPOT_CLIENT_ID") do
  config :ueberauth, Ueberauth.Strategy.HubSpot.OAuth,
    client_id: System.get_env("HUBSPOT_CLIENT_ID"),
    client_secret: System.get_env("HUBSPOT_CLIENT_SECRET")
end

if System.get_env("OPENAI_API_KEY") do
  config :openai,
    api_key: System.get_env("OPENAI_API_KEY"),
    organization_key: System.get_env("OPENAI_ORGANIZATION_KEY"),
    http_options: [recv_timeout: 60_000]
end

if System.get_env("GUARDIAN_SECRET_KEY") do
  config :financial_agent, FinancialAgent.Guardian,
    issuer: "financial_agent",
    secret_key: System.get_env("GUARDIAN_SECRET_KEY"),
    ttl: {30, :days}
end


# ──────────────────────────────
# ✅ Only for releases: ensure server runs
# ──────────────────────────────
if System.get_env("PHX_SERVER") do
  config :financial_agent, FinancialAgentWeb.Endpoint, server: true
end

# ──────────────────────────────
# ✅ Production configuration for Render
# ──────────────────────────────
if config_env() == :prod do
  # Database
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      """

  config :financial_agent, FinancialAgent.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: true

  # Secret Key Base
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      """

  # Host and port 
  port = String.to_integer(System.get_env("PORT") || "10000")

  config :financial_agent, FinancialAgentWeb.Endpoint,
    http: [
      ip: {0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    force_ssl: [rewrite_on: [:x_forwarded_proto]],
    check_origin: false

  # Oban uses the Repo config above; no extra setup needed.

  # Logging
  if System.get_env("LOG_LEVEL") do
    config :logger, level: String.to_atom(System.get_env("LOG_LEVEL"))
  end
end
