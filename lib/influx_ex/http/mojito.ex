defmodule InfluxEx.HTTP.Mojito do
  @moduledoc """
  HTTP support for the Mojito library
  """

  @behaviour InfluxEx.HTTP

  alias InfluxEx.HTTP.Response

  @impl InfluxEx.HTTP
  def send_request(:get, url, headers, _payload) do
    url
    |> Mojito.get(headers)
    |> handle_response()
  end

  def send_request(:post, url, headers, payload) do
    url
    |> Mojito.post(headers, payload)
    |> handle_response()
  end

  def send_request(:delete, url, headers, _payload) do
    url
    |> Mojito.delete(headers)
    |> handle_response()
  end

  defp handle_response({:ok, response}) do
    {:ok, Response.new(response.status_code, response.body)}
  end

  defp handle_response({:error, _reason} = error) do
    error
  end
end
