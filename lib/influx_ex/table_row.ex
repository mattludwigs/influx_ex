defmodule InfluxEx.TableRow do
  @moduledoc """
  Rows for a response table

  These are normally contained in a `InfluxEx.tables()` data structure and
  represents a single row in a table.
  """

  @typedoc """
  Data structure for table row
  """
  @type t() :: %__MODULE__{
          measurement: InfluxEx.measurement(),
          value: term(),
          field: binary(),
          time: binary(),
          tags: %{binary() => binary()},
          result: binary()
        }

  defstruct [:measurement, :value, :field, :time, :tags, :result]

  @doc """
  Turn a single row of a table CSV into an `InfluxEx.TableRow.t()`
  """
  @spec from_csv_row([binary()], [binary()]) :: t()
  def from_csv_row(
        ["", result, _table, _start, _stop, time, value, field, measurement | tags],
        tag_names
      ) do
    row = %__MODULE__{
      result: result,
      time: time,
      value: value,
      field: field,
      measurement: measurement,
      tags: %{}
    }

    add_tags(row, tag_names, tags)
  end

  defp add_tags(row, tag_names, tag_values) do
    row_tags =
      tag_names
      |> Enum.zip(tag_values)
      |> Enum.reduce(%{}, fn {tag, value}, tags ->
        Map.put(tags, tag, value)
      end)

    %__MODULE__{row | tags: row_tags}
  end
end
