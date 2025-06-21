defmodule FinincialAgent.Repo do
  use Ecto.Repo,
    otp_app: :financial_agent,
        # -------------------- Postgres
    adapter: Ecto.Adapters.Postgres

  use Scrivener
end
