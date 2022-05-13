defmodule InfluxEx.JSONLibrary do
  @moduledoc """
  Behaviour for a JSON library that `InfluxEx` can use to encode and decode JSON
  payloads
  """

  @typedoc """
  A module that implements this behaviour
  """
  @type t() :: module()

  @doc """
  Encode an Elixir map into a JSON encoded string
  """
  @callback encode(map()) :: binary()

  @doc """
  Parse a JSON encoded string into an Elixir map
  """
  @callback decode(binary()) :: map()
end
