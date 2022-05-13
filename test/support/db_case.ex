defmodule InfluxEx.DBCase do
  use ExUnit.CaseTemplate

  alias InfluxEx.{Buckets, Client, ConflictError, Orgs}

  using do
    quote do
      import InfluxEx.DBCase
    end
  end

  setup do
    org_name = "testorg"
    client = Client.new("testtoken", port: 8087)

    client_with_org =
      case Orgs.create(client, org_name) do
        {:ok, org} ->
          %{client | org_id: org.id, org: org.name}

        {:error, %ConflictError{}} ->
          {:ok, %{orgs: [org]}} = Orgs.all(client, org: org_name)
          %{client | org_id: org.id, org: org.name}
      end

    on_exit(fn -> Orgs.delete(client_with_org, client_with_org.org_id) end)

    {:ok, client: client_with_org}
  end

  def with_buckets(client, bucket_names, test_runner) do
    buckets =
      Enum.map(bucket_names, fn bucket_name ->
        {:ok, bucket} = Buckets.create(client, bucket_name)

        bucket
      end)

    test_runner.(buckets)
  end

  def with_bucket(client, bucket_name, test_runner) do
    {:ok, bucket} = Buckets.create(client, bucket_name)

    test_runner.(bucket)
  end

  def with_data_in_bucket(client, bucket_name, generator, test_runner) do
    {precision, points} = generator.()
    {:ok, bucket} = Buckets.create(client, bucket_name)
    :ok = InfluxEx.write(client, bucket.name, points, precision: precision)

    test_runner.(bucket)
  end

  def with_org(client, org_name, test_runner) do
    {:ok, org} = Orgs.create(client, org_name)

    on_exit(fn -> Orgs.delete(client, org.id) end)

    test_runner.(org)
  end

  def with_orgs(client, org_names, test_runner) do
    orgs =
      Enum.map(org_names, fn org_name ->
        {:ok, org} = Orgs.create(client, org_name)
        org
      end)

    on_exit(fn -> Enum.each(orgs, fn org -> :ok = Orgs.delete(client, org.id) end) end)

    test_runner.(orgs)
  end
end
