defmodule InfluxEx.Orgs do
  @moduledoc """
  Module for working with organizations in InfluxDB
  """

  alias InfluxEx.API.SecurityAndAccess
  alias InfluxEx.{Client, Org}
  alias InfluxEx.HTTP.Request

  @typedoc """
  Options for searching orgs
  """
  @type search_opt() :: {:org, Org.name()}

  @typedoc """
  Options for creating an org
  """
  @type create_org_opt() :: {:description, binary()}

  @doc """
  Get a list of orgs

  Optionally you can filter for an org by the org name by passing the `:org`
  option.

  ```elixir
  InfluxEx.orgs(client, org: "theorg")
  ```
  """
  @spec all(Client.t(), [search_opt()]) ::
          {:ok, InfluxEx.response_list(Org)} | {:error, InfluxEx.error()}
  def all(client, opts \\ []) do
    opts
    |> SecurityAndAccess.orgs()
    |> Request.run(client)
  end

  @doc """
  Create a new org in the InfluxDB
  """
  @spec create(Client.t(), Org.name(), [create_org_opt()]) ::
          {:ok, Org.t()} | {:error, InfluxEx.error()}
  def create(client, org_name, opts \\ []) do
    org_name
    |> SecurityAndAccess.create_org(opts)
    |> Request.run(client)
  end

  @doc """
  Delete an org
  """
  @spec delete(Client.t(), Org.id()) :: :ok | {:error, InfluxEx.error()}
  def delete(client, org_id) do
    org_id
    |> SecurityAndAccess.delete_org()
    |> Request.run(client)
  end
end
