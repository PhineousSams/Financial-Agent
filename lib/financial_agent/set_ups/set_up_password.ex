defmodule FinancialAgent.SetUps.SetUpPassword do
  alias FinancialAgent.Repo
  alias FinancialAgent.Configs.PasswordConfig

  # FinancialAgent.SetUps.SetUpPassword.insert_password_maintenance()


  def insert_password_maintenance do
    password_maintenance = [
      %{name: "Default", min_characters: 8, max_characters: 128, repetitive_characters: 0, sequential_numeric: 0, reuse: 3, restriction: true, max_attempts: 3, force_change: 90, min_special: 0, min_numeric: 0, min_lower_case: 0, min_upper_case: 0, maker_id: 1, updated_by: 1},
    ]

    Enum.each(password_maintenance, fn password_maintenance_data ->
      %PasswordConfig{}
      |> PasswordConfig.changeset(password_maintenance_data)
      |> Repo.insert()
    end)
  end
end
