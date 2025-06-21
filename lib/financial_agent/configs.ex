defmodule FinincialAgent.Configs do
  import Ecto.Query, warn: false

  alias FinincialAgent.Repo
  alias FinincialAgent.Configs.PasswordConfig

  # ========= password configs context ============

  def list_tbl_password_configs do
    Repo.all(PasswordConfig)
  end

  def get_password_config!(id), do: Repo.get!(PasswordConfig, id)

  def create_password_config(attrs \\ %{}) do
    %PasswordConfig{}
    |> PasswordConfig.changeset(attrs)
    |> Repo.insert()
  end

  def update_password_config(%PasswordConfig{} = password_config, attrs) do
    password_config
    |> PasswordConfig.changeset(attrs)
    |> Repo.update()
  end

  def delete_password_config(%PasswordConfig{} = password_config) do
    Repo.delete(password_config)
  end

  def change_password_config(%PasswordConfig{} = password_config, attrs \\ %{}) do
    PasswordConfig.changeset(password_config, attrs)
  end

  def get_pasword_configs do
    PasswordConfig
    |> limit(1)
    |> Repo.one()
  end



end
