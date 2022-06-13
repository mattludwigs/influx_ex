defmodule InfluxEx.API.Resources do
  @moduledoc false

  alias InfluxEx.API.ResultList
  alias InfluxEx.{Bucket, Buckets, Org}
  alias InfluxEx.HTTP.Request

  @doc """
  Request for getting a list of buckets
  """
  @spec buckets() :: Request.t()
  def buckets() do
    Request.new("/buckets", handler: &handle_buckets_response/1)
  end

  defp handle_buckets_response(response) do
    {:ok, ResultList.handle_list_response(response, Bucket, :buckets)}
  end

  @doc """
  Create a request for creating a bucket
  """
  @spec create_bucket(Bucket.name(), Org.id(), [Buckets.create_bucket_opt()]) ::
          Request.t()
  def create_bucket(name, org_id, opts \\ []) do
    payload = create_bucket_payload(name, org_id, opts)

    Request.new("/buckets",
      method: :post,
      handler: &handle_create_bucket_response/1,
      payload: payload
    )
  end

  defp create_bucket_payload(name, org_id, opts) do
    %{name: name, orgID: org_id, retentionRules: retention_policy_from_opts(opts)}
    |> maybe_put_optional_create_bucket_payload_fields(opts)
  end

  defp retention_policy_from_opts(opts) do
    if rules = opts[:retention_rules] do
      rules
    else
      retention_policy_from_expires_in(opts[:expires_in], opts)
    end
  end

  defp shard_group_value(value, opts) do
    if opts[:group_shard] do
      value
    else
      0
    end
  end

  defp retention_policy_from_expires_in(nil, opts) do
    [
      %{
        everySeconds: 2_592_000,
        shardGroupDurationSeconds: shard_group_value(86_400, opts),
        type: :expire
      }
    ]
  end

  defp retention_policy_from_expires_in(:never, opts) do
    [
      %{
        everySeconds: 0,
        shardGroupDurationSeconds: shard_group_value(604_800, opts),
        type: :expire
      }
    ]
  end

  defp retention_policy_from_expires_in({days, :days}, opts) do
    seconds_in_day = 86_400

    [
      %{
        everySeconds: seconds_in_day * days,
        shardGroupDurationSeconds: shard_group_value(seconds_in_day, opts),
        type: :expire
      }
    ]
  end

  defp retention_policy_from_expires_in({hours, :hours}, opts) when hours in [48, 72] do
    seconds_in_hour = 3_600

    [
      %{
        everySeconds: seconds_in_hour * hours,
        shardGroupDurationSeconds: shard_group_value(86_400, opts),
        type: :expire
      }
    ]
  end

  defp retention_policy_from_expires_in({hours, :hours}, opts) do
    seconds_in_hour = 3_600

    [
      %{
        everySeconds: seconds_in_hour * hours,
        shardGroupDurationSeconds: shard_group_value(seconds_in_hour, opts),
        type: :expire
      }
    ]
  end

  defp retention_policy_from_expires_in({_, :years}, opts) do
    [
      %{
        everySeconds: 31_536_000,
        shardGroupDurationSeconds: shard_group_value(604_800, opts),
        type: :expire
      }
    ]
  end

  defp maybe_put_optional_create_bucket_payload_fields(payload, []) do
    payload
  end

  defp maybe_put_optional_create_bucket_payload_fields(payload, [{:rp, rp} | rest]) do
    payload
    |> Map.put(:rp, rp)
    |> maybe_put_optional_create_bucket_payload_fields(rest)
  end

  defp maybe_put_optional_create_bucket_payload_fields(payload, [
         {:schema_type, schema_type} | rest
       ]) do
    payload
    |> Map.put(:schemaType, schema_type)
    |> maybe_put_optional_create_bucket_payload_fields(rest)
  end

  defp maybe_put_optional_create_bucket_payload_fields(payload, [_ | rest]) do
    maybe_put_optional_create_bucket_payload_fields(payload, rest)
  end

  defp handle_create_bucket_response(response) do
    {:ok, Bucket.from_map(response.body)}
  end

  @doc """
  Delete a bucket request
  """
  @spec delete_bucket(Bucket.id()) :: Request.t()
  def delete_bucket(bucket_id) do
    Request.new("/buckets/#{bucket_id}", handler: &handle_delete_response/1, method: :delete)
  end

  defp handle_delete_response(%{status_code: 204}) do
    :ok
  end
end
