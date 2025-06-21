defmodule FinincialAgent.Workers.Helpers.PwdValidator do
  def custom_pwd_validation(type, password, configs) do
    case configs_by_type(type, configs) do
      {:ok, configs} ->
        value = configs.value

        case value == 0 do
          true ->
            {:ok, "Proceed"}

          false ->
            count = Enum.count(String.split(password, ~r//), &Regex.match?(configs.chars, &1))

            cond do
              count < value -> error(configs.type, "There must be atleast #{value} characters")
              true -> {:ok, "Proceed"}
            end
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp configs_by_type(:numeric, configs),
    do: {:ok, %{type: "Numeric", value: configs.min_numeric, chars: ~r/[0-9]/}}

  defp configs_by_type(:lowercase, configs),
    do: {:ok, %{type: "Lowercase", value: configs.min_lower_case, chars: ~r/[a-z]/}}

  defp configs_by_type(:uppercase, configs),
    do: {:ok, %{type: "Uppercase", value: configs.min_upper_case, chars: ~r/[A-Z]/}}

  defp configs_by_type(:special, configs),
    do: {:ok, %{type: "Special", value: configs.min_special, chars: ~r/[[:punct:]]/}}

  defp configs_by_type(_, _),
    do: {:error, "Configuration error, Please contact system adiminstartor!!"}

  def repetitive_characters(password, configs) do
    value = configs.repetitive_characters

    repetitive_character_count =
      password
      |> String.graphemes()
      |> Enum.group_by(& &1)
      |> Enum.filter(fn {_char, occurrences} -> length(occurrences) > 1 end)
      |> Enum.flat_map(fn {_char, occurrences} -> occurrences end)
      |> Enum.count()

    if repetitive_character_count >= value or value == 0 do
      {:ok, "Proceed"}
    else
      error("Repetitive", "there must be #{value} repetitive characters")
    end
  end

  def check_pwd_size(password, configs) do
    password_length = Kernel.byte_size(password)
    min_length = configs.min_characters
    max_length = configs.max_characters

    cond do
      password_length < min_length ->
        {:error, "Password is too short. It must be at least #{min_length} characters long."}

      password_length > max_length ->
        {:error, "Password is too long. It must be no more than #{max_length} characters long."}

      true ->
        {:ok, "Proceed"}
    end
  end

  def sequential_characters(password, configs) do
    value = configs.sequential_numeric

    count =
      password
      # Convert password to a list of graphemes (characters)
      |> String.graphemes()
      |> Enum.reduce({0, 0, nil}, fn
        char, {max_count, current_count, prev_char} when char == prev_char ->
          # If the current character matches the previous, increase the current count
          {max_count, current_count + 1, char}

        char, {max_count, current_count, _prev_char} ->
          # If the current character does not match the previous,
          # update max_count if necessary and reset current count
          {max(max_count, current_count), 1, char}
      end)
      |> (fn {max_count, current_count, _} -> max(max_count, current_count) end).()

    cond do
      count < value -> error("Sequencial", "There must be atleast #{value} characters")
      true -> {:ok, "Proceed"}
    end
  end

  defp error(type, msg), do: {:error, "Invalid number of #{type} characters; #{msg}"}
end
