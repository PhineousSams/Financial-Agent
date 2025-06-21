defmodule FinincialTool.Repo do
  use Ecto.Repo,
    otp_app: :financial_tool,
        # -------------------- Postgres
    adapter: Ecto.Adapters.Postgres
    
  use Scrivener
end
