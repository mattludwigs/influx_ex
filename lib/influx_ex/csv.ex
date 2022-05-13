defmodule InfluxEx.CSV do
  @moduledoc """
  Default CSV support for InfluxEx

  This uses `:nimble_csv` so you must add that library to your dependency list
  in your `mix.exs`:

  ```elixir
  {:nimble_csv, "~> 1.0"}
  ```
  """

  @behaviour InfluxEx.CSVLibrary

  @impl InfluxEx.CSVLibrary
  def parse_string(binary) do
    NimbleCSV.RFC4180.parse_string(binary, skip_headers: false)
  end
end
