defmodule FinancialAgent.Workers.Util.SMS do
  def user_sms(user, pwd) do
    """
      Dear #{user.first_name}, Your Pangea username is #{user.username}, and password is #{pwd}
    """
  end
end
