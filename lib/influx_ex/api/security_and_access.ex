defmodule InfluxEx.API.SecurityAndAccess do
  @moduledoc false

  alias InfluxEx.API.ResultList
  alias InfluxEx.HTTP.Request
  alias InfluxEx.{Org, Orgs}

  @doc """
  A request to get all the orgs
  """
  @spec orgs([Orgs.search_opt()]) :: Request.t()
  def orgs(opts \\ []) do
    query = build_orgs_query_params(%{}, opts)

    Request.new("/orgs", handler: &handle_orgs_list_response/1, query_params: query)
  end

  defp build_orgs_query_params(params, []) do
    params
  end

  defp build_orgs_query_params(params, [{:org, org} | rest]) do
    params
    |> Map.put(:org, org)
    |> build_orgs_query_params(rest)
  end

  defp build_orgs_query_params(params, [_ | rest]) do
    build_orgs_query_params(params, rest)
  end

  defp handle_orgs_list_response(response) do
    {:ok, ResultList.handle_list_response(response, Org, :orgs)}
  end

  @doc """
  """
  @spec create_org(Org.name(), [Orgs.create_org_opt()]) :: Request.t()
  def create_org(name, opts \\ []) do
    payload = maybe_add_optional_create_fields(%{name: name}, opts)
    Request.new("/orgs", method: :post, payload: payload, handler: &handle_create_org_response/1)
  end

  defp maybe_add_optional_create_fields(payload, []) do
    payload
  end

  defp maybe_add_optional_create_fields(payload, [{:description, desc} | rest]) do
    payload
    |> Map.put(:description, desc)
    |> maybe_add_optional_create_fields(rest)
  end

  defp handle_create_org_response(%{body: org_map}) do
    {:ok, Org.from_map(org_map)}
  end

  def delete_org(org_id) do
    Request.new("/orgs/#{org_id}", method: :delete)
  end
end
