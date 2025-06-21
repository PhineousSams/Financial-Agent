defmodule FinancialAgent.Workers.Util.FuzzyString do
  def sort_names(names, search_criteria) do
    Enum.sort_by(names, fn name -> search_criteria.(name) end)
  end

  # Loans.Workers.Util.FuzzyString.calculate_accuracy("John Doe", "Jane Doe")
  def calculate_accuracy(name1, name2) do
    name1 = String.downcase(name1)
    name2 = String.downcase(name2)

    longer_name = if String.length(name1) > String.length(name2), do: name1, else: name2
    shorter_name = if longer_name == name1, do: name2, else: name1

    common_chars = count_common_characters(longer_name, shorter_name)

    percentage_accuracy = common_chars / String.length(longer_name) * 100
    Float.round(percentage_accuracy, 2)
  end

  defp count_common_characters(longer_name, shorter_name) do
    Enum.count(String.graphemes(longer_name), fn char ->
      String.contains?(shorter_name, char)
    end)
  end
end
