defmodule InfluxEx.API.SystemInformation do
  @moduledoc false

  alias InfluxEx.HTTP.Request

  @doc """
  Make a request to check the health InfluxDB
  """
  @spec health() :: Request.t()
  def health() do
    Request.new("/health", handler: &health_response_handler/1)
  end

  defp health_response_handler(%{body: _body}) do
    :ok
  end
end
