defmodule InfluxEx.Point do
  @moduledoc """
  A single data point
  """

  @type opt() :: {:timestamp, integer()} | {:precision, System.time_unit()}

  @type t() :: %__MODULE__{
          measurement: InfluxEx.measurement(),
          tags: map(),
          fields: map(),
          timestamp: integer(),
          precision: System.time_unit()
        }

  defstruct measurement: nil, fields: %{}, tags: %{}, timestamp: nil, precision: :nanosecond

  @doc """
  Make a new point for a measurement

  ```elixir
  InfluxEx.Point.new("cpu")
  ```
  """
  @spec new(InfluxEx.measurement(), [opt()]) :: t()
  def new(measurement, opts \\ []) do
    precision = opts[:precision] || :nanosecond
    timestamp = opts[:timestamp] || System.system_time(precision)

    %__MODULE__{measurement: measurement, timestamp: timestamp, precision: precision}
  end

  @doc """
  Add  field to the point

  Fields are the values you want to track over time. You can think of these as
  the metric values.

  ```elixir
  "cpu"
  |> InfluxEx.Point.new()
  |> InfluxEx.Point.add_field("avg", 5)
  ```

  The above point is for the average CPU usage.

  A single point can container many fields.

  ```elixir
  "cpu"
  |> InfluxEx.Point.new()
  |> InfluxEx.Point.add_field("avg", 5)
  |> InfluxEx.Point.add_field("last_reading", 10)
  ```

  If you have all the measurements at once you can use
  `InfluxEx.Point.add_fields/2`.
  """
  @spec add_field(t(), binary() | atom(), integer() | float() | boolean() | binary()) :: t()
  def add_field(point, field_name, field_value) do
    %{point | fields: Map.put(point.fields, field_name, field_value)}
  end

  @doc """
  Add many fields at once

  ```elixir
  "cpu"
  |> InfluxEx.Point.new()
  |> InfluxEx.Point.add_fields(%{avg: 5, last_reading: 10})
  ```
  """
  @spec add_fields(t(), map()) :: t()
  def add_fields(point, fields) do
    %{point | fields: fields}
  end

  @doc """
  Add a tag to your point

  Tags are meta data about your point. For example, maybe the location of a
  device you are reading data from.

  ```elixir
  "cpu"
  |> InfluxEx.Point.new()
  |> InfluxEx.Point.add_tag(:location, "EU")
  ```

  You can add many tags at once using `InfluxEx.Point.add_tags/2`
  """
  @spec add_tag(t(), atom() | binary(), binary()) :: t()
  def add_tag(point, tag_name, tag_value) do
    %{point | tags: Map.put(point.tags, tag_name, tag_value)}
  end

  @doc """
  Add many tags to your point at once

  Tags are meta data about your point. For example, maybe the location of a
  device you are reading data from.

  ```elixir
  "cpu"
  |> InfluxEx.Point.new()
  |> InfluxEx.Point.add_tags(%{location: "EU", product: "Awesome Product"})
  ```

  You can add many tags at once using `InfluxEx.Point.add_tags/2`
  """
  @spec add_tags(t(), map()) :: t()
  def add_tags(point, tags) do
    %{point | tags: tags}
  end

  @doc """
  Turn the point into the line protocol format expected by the InfluxDB
  """
  def to_line_protocol(%{tags: tags} = point) when map_size(tags) == 0 do
    "#{point.measurement} #{fields_to_set(point)} #{Integer.to_string(point.timestamp)}"
  end

  def to_line_protocol(point) do
    "#{point.measurement},#{tags_to_set(point)} #{fields_to_set(point)} #{Integer.to_string(point.timestamp)}"
  end

  defp tags_to_set(point) do
    data_as_set(point.tags)
  end

  defp fields_to_set(point) do
    data_as_set(point.fields)
  end

  defp data_as_set(data) do
    data
    |> Enum.reduce("", fn {tn, tv}, str ->
      str <> "#{name_as_str(tn)}=#{value_as_str(tv)},"
    end)
    |> String.trim_trailing(",")
  end

  defp name_as_str(name) when is_atom(name) do
    Atom.to_string(name)
  end

  defp name_as_str(name) when is_binary(name) do
    name
  end

  defp value_as_str(value) when is_integer(value) do
    Integer.to_string(value) <> "i"
  end
  
  defp value_as_str(value) when is_float(value) do
    Float.to_string(value)
  end

  defp value_as_str(value) when is_boolean(value) do
    to_string(value)
  end

  defp value_as_str(value) when is_binary(value) do
    "\"" <> value <> "\""
  end

  defp value_as_str(value) when is_atom(value) do
    Atom.to_string(value)
  end
end
