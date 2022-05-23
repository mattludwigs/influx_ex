defmodule InfluxEx.HTTP.Request do
  @moduledoc """
  A request to InfluxDB
  """

  alias InfluxEx.{ConflictError, GenericError, InvalidPayloadError, NotFoundError}
  alias InfluxEx.HTTP.Response

  @type url() :: binary()

  @type headers() :: [{binary(), binary()}]

  @type request_handler() :: (Response.t() -> term() | {:error, GenericError.t()})

  @type payload() :: binary() | map()

  @type method() :: :get | :post | :delete

  @type t() :: %__MODULE__{
          method: method(),
          endpoint: binary(),
          payload: payload() | nil,
          query_params: map(),
          handler: request_handler() | nil
        }

  @type opt() ::
          {:payload, term()}
          | {:method, method()}
          | {:query_params, map()}
          | {:handler, request_handler()}

  defstruct endpoint: nil, payload: nil, method: :get, query_params: %{}, handler: nil

  @doc """
  Make a new `Request.t()`
  """
  @spec new(binary(), [opt()]) :: t()
  def new(endpoint, opts \\ []) do
    payload = opts[:payload]
    method = opts[:method] || :get
    query_params = opts[:query_params] || %{}

    %__MODULE__{
      endpoint: endpoint,
      payload: payload,
      method: method,
      query_params: query_params,
      handler: opts[:handler]
    }
  end

  def run(request, client) do
    with {:ok, response} <- send_request(request, client),
         {:ok, response} <- parse_body(request, response, client) do
      if request.handler do
        case request.handler.(response) do
          :ok -> :ok
          {:ok, _} = ok -> ok
          {:error, _reason} = error -> error
        end
      else
        :ok
      end
    end
  end

  defp parse_body(_, %{status_code: 204} = response, _client) do
    {:ok, response}
  end

  defp parse_body(%{endpoint: endpoint}, response, _client)
       when endpoint in ["/health", "/write"] do
    {:ok, response}
  end

  defp parse_body(%{endpoint: "/query"}, %{body: body} = response, _client) when is_list(body) do
    {:ok, response}
  end

  defp parse_body(%{endpoint: "/query"}, %{body: body} = response, client) when is_binary(body) do
    parsed = client.csv_library.parse_string(body)
    {:ok, %{response | body: parsed}}
  end

  defp parse_body(_request, %{body: body} = response, _client) when is_map(body) do
    {:ok, response}
  end

  defp parse_body(_request, response, client) do
    case client.json_library.decode(response.body) do
      {:ok, parsed} ->
        {:ok, %{response | body: parsed}}

      {:error, error} ->
        {:error,
         GenericError.exception(
           "Error parsing response json: #{inspect(response.body)}, reason: #{get_json_parse_error(error)}"
         )}
    end
  end

  defp get_json_parse_error(error) when is_atom(error) do
    "#{inspect(error)}"
  end

  defp get_json_parse_error(error) when is_struct(error) do
    map = Map.from_struct(error)

    case map[:message] do
      nil ->
        "unsupported reason"

      message ->
        message
    end
  end

  defp make_url(host, port, %{endpoint: endpoint}) when endpoint in ["/health"] do
    "#{host}:#{port}/#{endpoint}"
  end

  defp make_url(host, port, request) do
    params = URI.encode_query(request.query_params)

    "#{host}:#{port}/api/v2#{request.endpoint}?#{params}"
  end

  defp send_request(request, client) do
    url = make_url(client.host, client.port, request)

    case do_send_request(client, request, url, headers(client.token, request.endpoint)) do
      {:ok, %{status_code: status_code} = resp} when status_code < 400 ->
        {:ok, resp}

      {:ok, %{status_code: status_code} = resp} when status_code >= 400 ->
        handle_http_error(client, resp)

      error ->
        error
    end
  end

  defp do_send_request(client, %__MODULE__{method: :post, endpoint: endpoint} = req, url, headers)
       when endpoint in ["/write", "/query"] do
    client.http_client.send_request(:post, url, headers, req.payload)
  end

  defp do_send_request(client, %__MODULE__{method: :post} = req, url, headers) do
    payload = client.json_library.encode!(req.payload)
    client.http_client.send_request(:post, url, headers, payload)
  end

  defp do_send_request(client, %__MODULE__{method: method}, url, headers) do
    client.http_client.send_request(method, url, headers, nil)
  end

  defp headers(token, endpoint) do
    [
      {"Authorization", "Token #{token}"}
    ]
    |> headers_for_endpoint(endpoint)
  end

  defp headers_for_endpoint(headers, "/write") do
    headers ++ [{"Content-type", "text/plain; charset=utf-8"}, {"Accept", "application/json"}]
  end

  defp headers_for_endpoint(headers, "/query") do
    headers ++ [{"Content-type", "application/vnd.flux"}, {"Accept", "application/csv"}]
  end

  defp headers_for_endpoint(headers, _other) do
    headers ++ [{"Content-type", "application/json"}]
  end

  defp handle_http_error(_client, %{body: body}) when is_map(body) do
    {:error, make_exception(body)}
  end

  defp handle_http_error(client, %{body: body}) when is_binary(body) do
    {:ok, decoded} = client.json_library.decode(body)

    {:error, make_exception(decoded)}
  end

  defp make_exception(%{"code" => "conflict", "message" => message}) do
    ConflictError.exception(message)
  end

  defp make_exception(%{"code" => "invalid", "message" => message}) do
    InvalidPayloadError.exception(message)
  end

  defp make_exception(%{"code" => "not found", "message" => message}) do
    [resource | _] = String.split(message, " ")
    NotFoundError.exception(resource)
  end

  defp make_exception(%{"code" => code, "message" => message}) do
    GenericError.exception("error code: #{inspect(code)}, message: #{message}")
  end
end
