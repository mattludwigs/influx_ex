defmodule InfluxEx.Buckets do
  @moduledoc """
  Module for working with buckets in InfluxDB
  """

  alias InfluxEx.API.{Data, Resources}
  alias InfluxEx.{Bucket, Client, Org}
  alias InfluxEx.HTTP.Request

  @typedoc """
  Optional fields for creating a bucket

  You can either provide a list of `Bucket.retention_rule()` for maxim control
  over the bucket's data retention rules, or you can provide the short hand
  `Bucket.expires_in()` to the `:expires_in` option.

  By default the retention will by 30 days if no retention policy is provided.
  If both the `:retention_rules` field and the `:expires_in` field are provided
  the `:retention_rules` field will be used.
  """
  @type create_bucket_opt() ::
          {:retention_rules, [Bucket.retention_rule()]}
          | {:expires_in, Bucket.expires_in()}
          | {:rp, binary()}
          | {:schema_type, Bucket.schema_type()}
          | {:org_id, Org.id()}

  @doc """
  Get all the buckets
  """
  @spec all(Client.t()) :: {:ok, InfluxEx.response_list(Bucket.t())} | {:error, InfluxEx.error()}
  def all(client) do
    Request.run(Resources.buckets(), client)
  end

  @doc """
  Create a new bucket
  """
  @spec create(Client.t(), Bucket.name()) :: {:ok, Bucket.t()} | {:error, InfluxEx.error()}
  def create(client, bucket_name, opts \\ []) do
    org_id = client.org_id || opts[:org_id]

    bucket_name
    |> Resources.create_bucket(org_id, opts)
    |> Request.run(client)
  end

  @doc """
  Delete a bucket
  """
  @spec delete(Client.t(), Bucket.id()) :: :ok | {:error, InfluxEx.error()}
  def delete(client, bucket_id) do
    bucket_id
    |> Resources.delete_bucket()
    |> Request.run(client)
  end

  @doc """
  Get the measurements in a bucket
  """
  @spec get_measurements(Client.t(), Bucket.name(), [InfluxEx.query_opt()]) ::
          {:ok, [binary()]} | {:error, InfluxEx.error()}
  def get_measurements(client, bucket, opts \\ []) do
    opts = Keyword.put_new(opts, :org, client.org)

    bucket
    |> get_measurements_query()
    |> Data.schema_query(opts)
    |> Request.run(client)
  end

  @doc """
  Get field keys for a measurement that is in a bucket
  """
  @spec get_measurement_field_keys(Client.t(), Bucket.name(), binary(), [
          InfluxEx.query_opt()
        ]) ::
          {:ok, [binary()]} | {:error, InfluxEx.error()}
  def get_measurement_field_keys(client, bucket, measurement, opts \\ []) do
    opts = Keyword.put_new(opts, :org, client.org)

    bucket
    |> get_measurement_field_keys_query(measurement)
    |> Data.schema_query(opts)
    |> Request.run(client)
  end

  defp get_measurements_query(bucket) do
    """
    import "influxdata/influxdb/schema"

    schema.measurements(bucket: #{inspect(bucket)})
    """
  end

  defp get_measurement_field_keys_query(bucket, measurement, opts \\ []) do
    start = opts[:start] || "-30d"

    """
    import "influxdata/influxdb/schema"

    schema.measurementFieldKeys(
      bucket: #{inspect(bucket)},
      measurement: #{inspect(measurement)},
      start: #{start},
    )
    """
  end
end
