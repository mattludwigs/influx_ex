defmodule InfluxEx.Bucket do
  @moduledoc """
  Data structure for a Bucket in InfluxDB
  """

  @type schema_type() :: :implicit | :explicit

  @typedoc """
  The type of the bucket

  `:user` - a user created this bucket
  `:system` - a bucket that is crated and used by InfluxDB
  """
  @type type() :: :user | :system

  @typedoc """
  Name of a bucket
  """
  @type name() :: binary()

  @typedoc """
  The id of a bucket
  """
  @type id() :: binary()

  @typedoc """
  When data should expire in a bucket

  This is useful for creating bucket as a short hand to generate a `retention_rule()`
  """
  @type expires_in() ::
          :never | {7 | 14 | 30 | 90, :days} | {1 | 6 | 12 | 24 | 48 | 72, :hours} | {1, :years}

  @typedoc """
  Data retention rule for the bucket

  * `:every_seconds` - duration in seconds for how long data will be kept in the
    database. `0` means infinite.
  * `:shared_group_duration_seconds` - shard duration measured in seconds
  * `:type` - is `:expire`
  """
  @type retention_rule() :: %{
          every_seconds: integer(),
          shard_group_duration_seconds: integer(),
          type: :expire
        }

  @typedoc """

  """
  @type links() :: %{
          labels: binary(),
          members: binary(),
          org: binary(),
          owners: binary(),
          self: binary(),
          write: binary()
        }

  @type t() :: %__MODULE__{
          name: name(),
          retention_rules: [retention_rule()],
          created_at: DateTime.t() | nil,
          id: id() | nil,
          labels: [map()],
          links: links() | nil,
          org_id: binary(),
          rp: binary() | nil,
          schema_type: schema_type() | nil,
          type: type() | nil,
          updated_at: DateTime.t() | nil,
          description: binary() | nil
        }

  defstruct name: nil,
            retention_rules: [],
            labels: [],
            links: [],
            type: nil,
            org_id: nil,
            id: nil,
            rp: nil,
            schema_type: nil,
            updated_at: nil,
            created_at: nil,
            description: nil

  @doc """
  Build a Bucket from a lose map returned from the InfluxDB API
  """
  @spec from_map(map()) :: t()
  def from_map(weak_map) do
    bucket = %__MODULE__{}

    Enum.reduce(weak_map, bucket, fn fields, bucket ->
      update_fields(fields, bucket)
    end)
  end

  defp update_fields({"name", name}, bucket) do
    %{bucket | name: name}
  end

  defp update_fields({"retentionRules", rules}, bucket) do
    rules =
      Enum.map(rules, fn rule ->
        %{
          every_seconds: rule["everySeconds"],
          shard_group_duration_seconds: rule["shardGroupDurationSeconds"],
          type: rule_type_to_atom(rule["type"])
        }
      end)

    %{bucket | retention_rules: rules}
  end

  defp update_fields({field, iso8601_string}, bucket) when field in ["createdAt", "updatedAt"] do
    {:ok, datetime, 0} = DateTime.from_iso8601(iso8601_string)
    update_datetime_field(bucket, field, datetime)
  end

  defp update_fields({"id", id}, bucket) do
    %{bucket | id: id}
  end

  defp update_fields({"labels", []}, bucket) do
    %{bucket | labels: []}
  end

  defp update_fields({"links", links}, bucket) do
    links =
      Enum.reduce(links, %{}, fn
        {"self", self}, l -> Map.put(l, :self, self)
        {"members", m}, l -> Map.put(l, :members, m)
        {"org", org}, l -> Map.put(l, :org, org)
        {"labels", labels}, l -> Map.put(l, :labels, labels)
        {"owners", owners}, l -> Map.put(l, :owners, owners)
        {"write", write}, l -> Map.put(l, :write, write)
      end)

    %{bucket | links: links}
  end

  defp update_fields({"orgID", org_id}, bucket) do
    %{bucket | org_id: org_id}
  end

  defp update_fields({"type", "user"}, bucket) do
    %{bucket | type: :user}
  end

  defp update_fields({"type", "system"}, bucket) do
    %{bucket | type: :system}
  end

  defp update_fields({"description", desc}, bucket) do
    %{bucket | description: desc}
  end

  defp update_datetime_field(bucket, "createdAt", datetime), do: %{bucket | created_at: datetime}
  defp update_datetime_field(bucket, "updatedAt", datetime), do: %{bucket | updated_at: datetime}

  defp rule_type_to_atom("expire"), do: :expire
end
