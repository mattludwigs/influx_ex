defmodule InfluxEx.HTTP.Response do
  @moduledoc """
  A response from the InfluxDB server
  """

  alias InfluxEx.HTTP

  @type t() :: %__MODULE__{
          body: map() | binary() | list(),
          status_code: HTTP.status_code()
        }

  defstruct body: "", status_code: nil

  @doc """
  Make a new response structure
  """
  @spec new(HTTP.status_code(), binary()) :: t()
  def new(status_code, body) do
    %__MODULE__{body: body, status_code: status_code}
  end
end
