defmodule InfluxEx.CSVLibrary do
  @moduledoc """
  Behaviour for a CSV library to implement

  By default InfluxEx will try to use `InfluxEx.CSV` which using `:nimble_csv`
  under the hood. If you want to use a different CSV library you can implement
  this behaviour for your library and pass the implementation module to the
  `:csv_library` option in `InfluxEx.Client.new/2`.
  """

  @typedoc """
  A modules that implements this behaviour
  """
  @type t() :: module()

  @doc """
  Parse a CSV string into a list of rows (lists)
  """
  @callback parse_string(binary()) :: [[binary()]]
end
