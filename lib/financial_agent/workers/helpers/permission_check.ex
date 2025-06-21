defmodule FinincialTool.Workers.Helpers.PermissionsCheck do
  @moduledoc false
  def page_access(page, permissions), do: Enum.member?(permissions, page)
end
