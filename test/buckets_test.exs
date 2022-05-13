defmodule InfluxEx.BucketsTest do
  use InfluxEx.DBCase

  alias InfluxEx.{Bucket, Flux, GenData, Point}
  alias InfluxEx.Buckets

  test "create with default 30 day retention rule", %{client: client} do
    assert {:ok, %Bucket{} = bucket} = Buckets.create(client, "createbucket")

    assert bucket.name == "createbucket"

    [rule] = bucket.retention_rules

    assert rule ==
             %{
               every_seconds: 2_592_000,
               shard_group_duration_seconds: 86400,
               type: :expire
             }
  end

  test "getting a list of buckets", %{client: client} do
    with_buckets(client, ["bucket1", "bucket2", "bucket3"], fn buckets ->
      {:ok, %{buckets: buckets_list}} = Buckets.all(client)

      for b <- buckets do
        assert b in buckets_list
      end
    end)
  end

  test "deleting a bucket", %{client: client} do
    with_bucket(client, "deleteme", fn bucket ->
      assert :ok = Buckets.delete(client, bucket.id)
    end)
  end

  test "write a single point to a bucket", %{client: client} do
    with_bucket(client, "I has a point", fn bucket ->
      point =
        "number"
        |> Point.new(precision: :second)
        |> Point.add_field("avg", 100)
        |> Point.add_tag("loc", "here")

      :ok = InfluxEx.write(client, bucket.name, point, precision: :second)
    end)
  end

  test "write a list of points to a bucket", %{client: client} do
    with_bucket(client, "I has many pointz", fn bucket ->
      points = GenData.generate_vm_memory_metrics()
      assert length(points) == 300

      :ok = InfluxEx.write(client, bucket.name, points, precision: :second)
    end)
  end

  test "basic no tags query", %{client: client} do
    with_data_in_bucket(
      client,
      "abucket",
      fn -> {:second, GenData.generate_vm_memory_metrics()} end,
      fn bucket ->
        query =
          Flux.from(bucket.name)
          |> Flux.measurement("vm.memory")
          |> Flux.range("-7m")
          |> Flux.field("total")
          |> to_string()

        assert {:ok, %{0 => results}} = InfluxEx.query(client, query)

        length(results) == 300
      end
    )
  end
end
