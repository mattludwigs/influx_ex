defmodule InfluxEx.API.Users do
  @moduledoc false

  alias InfluxEx.HTTP.Request
  alias InfluxEx.Me

  @doc """
  Make a request to get information for the current authenticated user
  """
  @spec me() :: Request.t()
  def me() do
    Request.new("/me", handler: &handle_me_response/1)
  end

  defp handle_me_response(%{body: me_map}) do
    {:ok, Me.from_map(me_map)}
  end
end
