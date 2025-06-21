defmodule FinincialAgent.Workers.Util.HtmlTagRemover do
  # Loans.Workers.Util.HtmlTagRemover.remove_html_tags(<a><strong>Investor Guide</strong></a>)
  def remove_html_tags(html) do
    # Regular expression to match HTML tags
    pattern = ~r/<[^>]*>/
    # Regex.replace(html, pattern, "", global: true)
    String.replace(html, pattern, "")
  end

  # Loans.Workers.Util.HtmlTagRemover.processed_mdt_img_dir()
  def processed_mdt_img_dir do
    dir = "D:/"
    date_path = Timex.format!(Timex.local(), "%Y/%b/%F", :strftime)

    Path.join(String.trim(to_string(dir)), date_path)
    |> default_dir()
  end

  def default_dir(path) do
    File.mkdir_p(path)
    path
  end
end
