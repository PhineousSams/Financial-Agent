defmodule FinincialTool.Workers.Util.Helpers do

  alias FinincialTool.Notifications.Sms
  alias FinincialTool.Workers.Util.SMS

  # ===================== log User sms =============================
  def log_user_sms(user, pwd) do
    msg = SMS.user_sms(user, pwd)
    prep_sms = %{type: "PWD", mobile: user.phone, sms: msg, msg_count: 0, status: "PENDING"}

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user_sms, Sms.changeset(%Sms{}, prep_sms))
  end


  def sanitize(level_name) do
    String.trim_trailing(level_name, " ")
    |> String.trim_leading(" ")
    |> String.downcase()
    |> String.replace(" ", "_")
  end
end

# Loans.Workers.Util.Helpers.sample_file()
