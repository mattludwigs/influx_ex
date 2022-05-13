defmodule InfluxEx.Me do
  @moduledoc """
  Data structure for the current user using the InfluxDB API
  """

  @typedoc """
  Links to other resources for the current user
  """
  @type links() :: %{
          required(:self) => binary()
        }

  @typedoc """
  The status of the current user
  """
  @type status() :: :active

  @type t() :: %__MODULE__{
          id: binary(),
          links: links(),
          name: binary(),
          status: status()
        }

  defstruct [:id, :links, :name, :status]

  @doc """
  Transform a map returned from InfluxDB API into a `InfluxEx.Me.t()`
  """
  @spec from_map(map()) :: t()
  def from_map(%{"id" => id, "links" => links, "name" => name, "status" => status}) do
    %__MODULE__{
      id: id,
      links: links_from_map(links),
      name: name,
      status: status_from_string(status)
    }
  end

  defp links_from_map(links) do
    Enum.reduce(links, %{}, fn
      {"self", self_endpoint}, links_map ->
        Map.put(links_map, :self, self_endpoint)

      _, links_map ->
        links_map
    end)
  end

  defp status_from_string("active"), do: :active
end
