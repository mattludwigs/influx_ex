defmodule InfluxEx.Flux do
  @moduledoc """
  Functions to build Flux queries

  Current time related functionality only supports flux's duration types, for
  this is a value such has `15m`. Where `15` is the number of the unit that
  follows, which in this case is `m` meaning minutes.

  For more information about duration types see the
  [Flux docs](https://docs.influxdata.com/flux/v0.x/spec/types/#duration-types).

  The `%InfluxEx.Flux{}` struct implements the `String.Chars` protocol which
  allows `to_string/1` to be called on the structure.
  """

  alias InfluxEx.{Bucket, Client}

  @type aggregate_window_opt() :: {:create_empty, boolean()}

  @type aggregate_selector() :: :mean

  @type aggregate_window() :: %{
          every: binary(),
          create_empty: false,
          fn: aggregate_selector()
        }

  @typedoc """
  Data structure for a flux query
  """
  @type t() :: %__MODULE__{
          bucket: Bucket.name(),
          start: binary() | nil,
          end: binary() | nil,
          measurement: binary() | nil,
          field: binary() | nil,
          tags: map(),
          aggregate_window: aggregate_window() | nil,
          fill_value_use_previous: boolean()
        }

  defstruct bucket: nil,
            start: nil,
            end: nil,
            measurement: nil,
            field: nil,
            tags: %{},
            aggregate_window: nil,
            fill_value_use_previous: false

  @doc """
  Set the bucket for the query

  This function starts a new flux query.

  ```elixir
  InfluxEx.Flux.from("my bucket")
  ```
  """
  @spec from(Bucket.name()) :: t()
  def from(bucket) do
    %__MODULE__{bucket: bucket}
  end

  @doc """
  Set the time range for the query

  To query a bucket over the last 15 minutes, you can use `range/3`:

  ```elixir
  "my_bucket"
  |> InfluxEx.Flux.from()
  |> InfluxEx.Flux.range("-15m")
  ```
  """
  @spec range(t(), binary(), binary() | nil) :: t()
  def range(f, start, end_t \\ nil) do
    %__MODULE__{f | start: start, end: end_t}
  end

  @doc """
  Set which field the query is for

  ```elixir
  "my_bucket"
  |> InfluxEx.Flux.from()
  |> InfluxEx.Flux.range("-15m")
  |> InfluxEx.Flux.measurement("cpu")
  |> InfluxEx.Flux.field("average")
  ```
  """
  @spec field(t(), binary()) :: t()
  def field(f, field) do
    %__MODULE__{f | field: field}
  end

  @doc """
  Set the measurement name to query for

  ```elixir
  "my_bucket"
  |> InfluxEx.Flux.from()
  |> InfluxEx.Flux.range("-15m")
  |> InfluxEx.Flux.measurement("cpu")
  ```
  """
  @spec measurement(t(), binary()) :: t()
  def measurement(f, measurement) do
    %__MODULE__{f | measurement: measurement}
  end

  @doc """
  Set a tag to filter against
  """
  @spec tag(t(), atom() | binary(), binary()) :: t()
  def tag(f, tag_name, tag_value) when is_atom(tag_name) do
    tag(f, Atom.to_string(tag_name), tag_value)
  end

  def tag(f, tag_name, tag_value) when is_binary(tag_name) do
    tags = Map.put(f.tags, tag_name, tag_value)
    %__MODULE__{f | tags: tags}
  end

  @doc """
  Add an aggregate window

  """
  @spec aggregate_window(t(), binary(), [aggregate_window_opt()]) :: t()
  def aggregate_window(f, every, opts \\ []) do
    create_empty = opts[:create_empty] || false
    window = %{every: every, fn: :mean, create_empty: create_empty}

    %{f | aggregate_window: window}
  end

  @doc """
  Fill missing values with the previous one

  This is useful for setting the `:create_empty` field to `true` when using
  `Flux.aggregate_window/3`.

  ```elixir
  "my bucket"
  |> InfluxEx.Flux.from()
  |> InfluxEx.Flux.range("-1d")
  |> InfluxEx.Flux.measurement("cpu")
  |> InfluxEx.Flux.field("average")
  |> InfluxEx.Flux.aggregate_window("1h", create_empty: true)
  |> InfluxEx.Flux.fill_value_previous()
  ```

  The above query will return tables with data over the last day averaged in one
  hour intervals. Where there's missing data points, the query will fill the
  value with the last data point's value.
  """
  def fill_value_previous(f) do
    %{f | fill_value_use_previous: true}
  end

  @doc """
  Run the flux query
  """
  @spec run_query(t(), Client.t()) :: {:ok, InfluxEx.tables()} | {:error, InfluxEx.error()}
  def run_query(flux_query, client, opts \\ []) do
    query = to_string(flux_query)

    InfluxEx.query(client, query, opts)
  end

  defimpl String.Chars do
    def to_string(f) do
      case validate(f) do
        :ok ->
          """
          #{from_to_string(f)}
          |> #{range_to_string(f)}
          |> #{measurement_to_string(f)}
          |> #{field_to_string(f)}
          #{tags_to_string(f)}
          """
          |> add_aggregate_window_to_string(f)
          |> add_value_fill(f)

        {:error, missing} ->
          raise ArgumentError, """
          Flux query is missing require fields

          #{inspect(missing)}
          """
      end
    end

    defp from_to_string(f) do
      "from(bucket: #{inspect(f.bucket)})"
    end

    defp range_to_string(f) do
      "range(start: #{f.start})"
    end

    defp measurement_to_string(f) do
      "filter(fn: (r) => r._measurement == #{inspect(f.measurement)})"
    end

    defp field_to_string(f) do
      "filter(fn: (r) => r._field == #{inspect(f.field)})"
    end

    defp add_aggregate_window_to_string(query_string, flux) do
      case flux.aggregate_window do
        nil ->
          query_string

        window ->
          query_string <>
            "\n" <>
            "|> aggregateWindow(every: #{window.every}, fn: #{window.fn}, createEmpty: #{window.create_empty})"
      end
    end

    defp add_value_fill(query_string, flux) do
      if flux.fill_value_use_previous do
        query_string <>
          "\n" <>
          """
          |> fill(column: "_value", usePrevious: true)
          """
      else
        query_string
      end
    end

    defp validate(flux) do
      required = [:bucket, :measurement, :field, :start]

      flux
      |> Map.from_struct()
      |> do_validate(required, [])
    end

    defp do_validate(_, [], []) do
      :ok
    end

    defp do_validate(_, [], missing) do
      {:error, missing}
    end

    defp do_validate(flux, [required | rest], missing) do
      if flux[required] do
        do_validate(flux, rest, missing)
      else
        do_validate(flux, rest, [required | missing])
      end
    end

    defp tags_to_string(flux) do
      # we should improve the query to filter tags in one filter call when
      # possible
      Enum.reduce(flux.tags, "", fn {tag, value}, str ->
        str <> "|> filter(fn: (r) => r[#{inspect(tag)}] == #{inspect(value)})\n"
      end)
    end
  end
end
