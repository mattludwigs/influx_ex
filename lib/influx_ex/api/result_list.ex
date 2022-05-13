defmodule InfluxEx.API.ResultList do
  @moduledoc false

  # Helper modules for endpoints that return a list of a resource

  alias InfluxEx.HTTP.Response

  @doc """
  Handle when the response is a list of a resource
  """
  @spec handle_list_response(Response.t(), module(), atom()) :: InfluxEx.response_list(module())
  def handle_list_response(response, resource, resource_key) do
    links = get_response_links(response.body)
    resource_string_key = Atom.to_string(resource_key)

    list = many(resource, response.body[resource_string_key])
    response_list = %{links: links}

    Map.put(response_list, resource_key, list)
  end

  defp many(resource, data) do
    Enum.reduce(data, [], fn data, result ->
      r = resource.from_map(data)
      result ++ [r]
    end)
  end

  defp get_response_links(%{"links" => links}) do
    Enum.reduce(links, %{}, fn
      {"self", self}, l -> Map.put(l, :self, self)
      {"next", next}, l -> Map.put(l, :next, next)
      {"prev", prev}, l -> Map.put(l, :prev, prev)
    end)
  end
end
