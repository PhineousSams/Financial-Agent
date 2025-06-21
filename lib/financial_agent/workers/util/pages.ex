defmodule FinancialAgent.Workers.Util.Pages do
  import Ecto.Query, warn: false
  import Plug.Conn

  alias FinancialAgent.Repo

  def calculate_page_num(nil, _), do: 1

  def calculate_page_num(start, length) do
    start = String.to_integer(start)
    round(start / length + 1)
  end

  def calculate_page_size(nil), do: 10
  def calculate_page_size(length), do: String.to_integer(length)

  def total_entries(%{total_entries: total_entries}), do: total_entries
  def total_entries(_), do: 0

  def entries(%{entries: entries}), do: entries
  def entries(_), do: []

  def search_options(params) do
    length = calculate_page_size(params["length"])
    page = calculate_page_num(params["start"], length)

    draw =
      try do
        String.to_integer(params["draw"])
      rescue
        _ -> params["draw"]
      end

    params = Map.put(params, "isearch", params["search"]["value"])

    new_params =
      Enum.reduce(~w(columns order search length draw start _csrf_token), params, fn key, acc ->
        Map.delete(acc, key)
      end)

    {draw, page, length, new_params}
  end

  def display(draw, results) do
    total_entries = total_entries(results)

    _results = %{
      draw: draw,
      recordsTotal: total_entries,
      recordsFiltered: total_entries,
      data: entries(results) |> Enum.map(&sanitize_params/1)
    }
  end

  defp sanitize_params(params) do
    Enum.reduce(params, %{}, fn {k, value}, acc ->
      val =
        cond do
          String.valid?(value) ->
            term =
              value
              |> String.to_charlist()
              |> Enum.filter(&(&1 in 0..127))
              |> List.to_string()

            for <<c <- term>>, c in 0..127, into: "", do: <<c>>

          true ->
            binary_to_string = fn str ->
              if is_binary(str), do: Enum.join(for <<c::utf8 <- str>>, do: <<c::utf8>>), else: str
            end

            binary_to_string.(value)
        end

      Map.put(acc, k, val)
    end)
  end

  def chunk_rows(queryable, chunk_size) do
    stream =
      Stream.unfold(0, fn offset ->
        query =
          from q in queryable,
            limit: ^chunk_size,
            offset: ^offset

        case Repo.all(query) do
          [] -> nil
          results -> {results, offset + chunk_size}
        end
      end)

    Stream.concat(stream)
  end

  def chunk_rows(queryable, _chunk_size, conn) do
    #    {:ok, conn} =
    Repo.transaction(fn ->
      queryable
      |> Enum.reduce_while(conn, fn data, conn ->
        case chunk(conn, data) do
          {:ok, conn} ->
            {:cont, conn}

          {:error, :closed} ->
            {:halt, conn}
        end
      end)
    end)

    conn
  end
end
