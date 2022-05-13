defmodule InfluxEx.OrgsTest do
  use InfluxEx.DBCase

  alias InfluxEx.{ConflictError, Orgs}

  test "create a new org", %{client: client} do
    with_org(client, "org1", fn org ->
      assert org.name == "org1"
    end)
  end

  test "try to create the same org twice", %{client: client} do
    with_org(client, "firstone", fn _org ->
      assert {:error, %ConflictError{}} = Orgs.create(client, "firstone")
    end)
  end

  test "get all orgs", %{client: client} do
    with_orgs(client, ["another", "org!"], fn created_orgs ->
      {:ok, %{orgs: orgs}} = Orgs.all(client)

      for org <- created_orgs do
        assert org in orgs
      end
    end)
  end

  test "search for one org", %{client: client} do
    with_orgs(client, ["another", "org!"], fn _ ->
      {:ok, %{orgs: orgs}} = Orgs.all(client, org: "org!")

      assert [org] = orgs
      assert org.name == "org!"
    end)
  end

  test "delete an org", %{client: client} do
    with_org(client, "delete me!", fn org ->
      assert :ok = Orgs.delete(client, org.id)
    end)
  end
end
