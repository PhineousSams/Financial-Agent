defmodule FinancialAgent.Workers.Helpers.UserLog do
  alias FinancialAgent.Repo
  alias FinancialAgent.Logs.UserLogs

  def log_user_log(activity, user) do
    user_log = %{user_id: user.id, activity: activity}
    UserLogs.changeset(%UserLogs{}, user_log) |> Repo.insert()
  end
end
