defmodule InfluxEx.HTTP do
  @moduledoc """
  Behaviour for HTTP clients

  By default `InfluxEx` will try to use the `Mojito` library to make HTTP
  requests, however, if you prefer or use another HTTP library you can
  implement this behaviour for your HTTP library to integer with `InfluxEx`
  """

  alias InfluxEx.HTTP.{Request, Response}

  @typedoc """
  A module that implements the HTTP behaviour
  """
  @type t() :: module()

  @type status_code() :: 100..599

  @doc """
  Send a request

  `InfluxEx` tries to all the heavy lifting for you, so you only have to worry
  about sending the request.

  For building the response you only need to pass through the status code and
  the body. You don't need to worry about parsing the body as `InfluxEx` can
  handle that in a generic way.
  """
  @callback send_request(
              Request.method(),
              Request.url(),
              Request.headers(),
              Request.payload() | nil
            ) ::
              {:ok, Response.t()} | {:error, term()}
end
