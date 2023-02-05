defmodule InfluxEx.HTTP.Req do
  @moduledoc """
  `InfluxEx.HTTP` implementation for the Req library
  """

  @behaviour InfluxEx.HTTP

  alias InfluxEx.HTTP.Response

  @impl InfluxEx.HTTP
  def send_request(:get, url, headers, _payload) do
    url
    |> Req.get!(headers: headers)
    |> handle_response()
  end

  def send_request(:post, url, headers, payload) do
    url
    |> Req.post!(body: payload, headers: headers)
    |> handle_response()
  end

  def send_request(:delete, url, headers, _payload) do
    url
    |> Req.delete!(headers: headers)
    |> handle_response()
  end

  defp handle_response(%Req.Response{} = req_resp) do
    {:ok, Response.new(req_resp.status, req_resp.body)}
  end
end
