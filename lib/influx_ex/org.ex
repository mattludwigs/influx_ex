defmodule InfluxEx.Org do
  @moduledoc """
  Data structure for an Org in InfluxDB
  """

  @type status() :: :active | :inactive

  @type id() :: binary()

  @type name() :: binary()

  @type links() :: %{
          buckets: binary(),
          dashboards: binary(),
          labels: binary(),
          members: binary(),
          owners: binary(),
          secrets: binary(),
          self: binary(),
          tasks: binary()
        }

  @type t() :: %__MODULE__{
          id: id() | nil,
          name: name(),
          description: binary() | nil,
          status: status() | nil,
          links: links(),
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct id: nil,
            name: nil,
            description: nil,
            status: nil,
            links: %{},
            created_at: nil,
            updated_at: nil

  def from_map(weak_map) do
    %__MODULE__{
      id: weak_map["id"],
      name: weak_map["name"],
      description: weak_map["description"],
      links: links_from_map(weak_map),
      status: parse_status(weak_map["status"]),
      created_at: parse_datetime(weak_map["createdAt"]),
      updated_at: parse_datetime(weak_map["updatedAt"])
    }
  end

  defp links_from_map(%{"links" => links}) do
    Enum.reduce(
      links,
      %{},
      fn
        {"buckets", buckets}, ls -> Map.put(ls, :buckets, buckets)
        {"dashboards", dashboards}, ls -> Map.put(ls, :dashboards, dashboards)
        {"labels", labels}, ls -> Map.put(ls, :labels, labels)
        {"members", members}, ls -> Map.put(ls, :members, members)
        {"owners", owners}, ls -> Map.put(ls, :owners, owners)
        {"secrets", secrets}, ls -> Map.put(ls, :secrets, secrets)
        {"self", self}, ls -> Map.put(ls, :self, self)
        {"tasks", tasks}, ls -> Map.put(ls, :tasks, tasks)
        {"logs", logs}, ls -> Map.put(ls, :logs, logs)
      end
    )
  end

  defp parse_datetime(iso8601_string) do
    {:ok, datetime, 0} = DateTime.from_iso8601(iso8601_string)
    datetime
  end

  defp parse_status(nil), do: nil

  defp parse_status("active") do
    :active
  end

  defp parse_status("inactive") do
    :inactive
  end
end
