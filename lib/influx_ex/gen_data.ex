defmodule InfluxEx.GenData do
  @moduledoc """
  Module for generating series of data, mostly useful for development and test
  """

  alias InfluxEx.Point

  @typedoc """
  Define how after back the time window can go in minutes
  """
  @type window_def() :: {integer(), :minute}

  @typedoc """
  Define fields and what value(s) a field can contain

  ### Random generated value

  If you want the generation code to generate an integer for you just have to
  specify the name of the field

  ```elixir
  InfluxDB.GenData.generate("my.measurement", [:temp, :humidity])
  ```

  ### Specific value

  If you want all the values of a field to be the same you can specify that by
  passing that value with the field name:

  ```elixir
  InfluxDB.GenData.generate("my.measurement", [{:temp, 100}, {:humidity, 50}])
  ```

  ### With a range of values

  If you want the fields to be in a specific range you can you pass the range
  along with the field name:

  ```elixir
  InfluxDB.GenData.generate("my.measurement", [{:temp, -20..130}])
  ```
  Values within the range are selected randomly.

  ### With a group of values

  If you have a known list of possible values you can pass a that list along
  with the field name:

  ```elixir
  InfluxDB.GenData.generate("my.measurement", [{:temp, [1, 5, 10]}])
  ```
  """
  @type field_def() :: atom() | {atom(), integer() | Range.t() | [term()]}

  @typedoc """
  A list of the unique tag sets to use to generate the data points
  """
  @type tags() :: [map()]

  @typedoc """
  Options to use when generating the data
  """
  @type gen_opt() ::
          {:tags, tags()}
          | {:window, window_def()}
          | {:precision, :second}

  def generate_vm_memory_metrics(opts \\ []) do
    fields = Keyword.keys(:erlang.memory())
    generate("vm.memory", fields, opts)
  end

  @doc """
  Generate data to be written to the InfluxDB

  By default this will generate enough data points for the last 5 minutes.
  Currently, only minute time windows are supported.

  By default the precision is in seconds and when writing the data using
  `InfluxEx.write/4` you will to pass the `:precision` option as `:second`.
  """
  @spec generate(InfluxEx.measurement(), [field_def()], [gen_opt()]) :: [Point.t()]
  def generate(measurement_name, fields, opts \\ []) do
    window = opts[:window] || {5, :minute}
    precision = opts[:precision] || :second
    tags = opts[:tags] || []
    total_number_of_points = num_of_points(window, precision)
    start_time = System.system_time(:second) - total_number_of_points

    Enum.reduce(0..(total_number_of_points - 1), [], fn i, points ->
      timestamp = start_time + i
      new_points = gen_points(measurement_name, timestamp, fields, tags, precision)

      points ++ new_points
    end)
  end

  defp gen_points(measurement_name, timestamp, fields, [], precision) do
    fields = gen_fields(fields, %{})

    point =
      measurement_name
      |> Point.new(timestamp: timestamp, precision: precision)
      |> Point.add_fields(fields)

    [point]
  end

  defp gen_points(measurement_name, timestamp, fields, tags, precision) do
    Enum.map(tags, fn tag_set ->
      fields = gen_fields(fields, %{})

      measurement_name
      |> Point.new(timestamp: timestamp, precision: precision)
      |> Point.add_tags(tag_set)
      |> Point.add_fields(fields)
    end)
  end

  defp gen_fields([], fields) do
    fields
  end

  defp gen_fields([field | rest], fields) when is_atom(field) do
    value = Enum.random(0..100)
    fields = Map.put(fields, field, value)

    gen_fields(rest, fields)
  end

  defp gen_fields([{field, %Range{} = range} | rest], fields) do
    value = Enum.random(range)
    fields = Map.put(fields, field, value)

    gen_fields(rest, fields)
  end

  defp gen_fields([{field, values} | rest], fields) when is_list(values) do
    value = Enum.random(values)
    fields = Map.put(fields, field, value)

    gen_fields(rest, fields)
  end

  defp gen_fields([{field, value} | rest], fields) do
    fields = Map.put(fields, field, value)

    gen_fields(rest, fields)
  end

  defp num_of_points({integer, :minute}, :second) do
    integer * 60
  end
end
