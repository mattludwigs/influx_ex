defmodule InfluxEx do
  @moduledoc """
  Functions for working with the primary Influx v2.x API
  """

  alias InfluxEx.{
    Bucket,
    Client,
    ConflictError,
    GenericError,
    InvalidPayloadError,
    Me,
    NotFoundError,
    Org,
    Point,
    TableRow
  }

  alias InfluxEx.API.{Data, SystemInformation, Users}
  alias InfluxEx.HTTP.Request

  @type error() ::
          ConflictError.t()
          | GenericError.t()
          | InvalidPayloadError.t()
          | NotFoundError.t()
          | term()

  @typedoc """
  The API token to make requests to the InfluxDB API
  """
  @type token() :: binary()

  @typedoc """
  Decoder function

  This function is ran to decode the body of a response
  """
  @type decoder() :: (iodata() -> {:ok, term()} | {:error, term()})

  @typedoc """
  Links for a response
  """
  @type response_links() :: %{
          required(:self) => binary(),
          optional(:next) => binary(),
          optional(:prev) => binary()
        }

  @typedoc """
  Returned when a list of a resource is returned by the API

  For example, when you send a request to the `/buckets` endpoint you will get
  a list of buckets along with various response links.
  """
  @type response_list(resource) :: %{
          required(:links) => response_links(),
          optional(atom()) => [resource]
        }

  @typedoc """
  Options for writing data points to InfluxDB

  When writing to InfluxDB, you must either provide an org name or an org id,
  if both are provided the org name takes precedence.

  If you configured your `InfluxDB.Client.t()` with an `:org` field, that value
  will be used by default. Otherwise, you must provided one of these values.
  """
  @type write_opt() :: {:precision, System.time_unit()} | {:org, Org.name()}

  @typedoc """
  Options used to query InfluxDB

  When querying InfluxDB, you must either provide an org name or an org id, if
  both are provided the org name takes precedence.

  If you configured your `InfluxDB.Client.t()` with an `:org` field, that value
  will be used by default. Otherwise, you must provide one of these values.
  """
  @type query_opt() :: {:org, Org.name()} | {:org_id, Org.id()}

  @typedoc """
  Tables are returned when querying InfluxDB

  Tables is map with integer key (the table) and a list of
  `InfluxEx.TableRow.t()`s as the value. You can think of each table as a new
  dataset. Normally, when the results are many tables, you have not filtered a
  tag out in your Flux query.
  """
  @type tables() :: %{required(integer()) => [TableRow.t()]}

  @typedoc """
  The name of a single measurement
  """
  @type measurement() :: binary()

  @doc """
  Get the health of the server

  Returns `:ok` if the server is ready to receive read and writes.
  """
  @spec health(Client.t()) :: :ok | {:error, error()}
  def health(client) do
    SystemInformation.health()
    |> Request.run(client)
  end

  @doc """
  Get the current user information
  """
  @spec me(Client.t()) :: {:ok, Me.t()} | {:error, error()}
  def me(client) do
    Users.me()
    |> Request.run(client)
  end

  @doc """
  Write one more data point(s) to InfluxDB
  """
  @spec write(Client.t(), Bucket.name(), Point.t() | [Point.t()], [write_opt()]) ::
          :ok
  def write(client, bucket, point_or_points, opts \\ []) do
    precision = opts[:precision] || :nanosecond
    org = opts[:org] || client.org

    org
    |> Data.write(bucket, point_or_points, precision)
    |> Request.run(client)
  end

  @doc """
  Send a query to InfluxDB to run
  """
  @spec query(Client.t(), binary(), [query_opt()]) ::
          {:ok, tables()} | {:error, error()}
  def query(client, query, opts \\ []) do
    opts = Keyword.put_new(opts, :org, client.org)

    case Data.query(query, opts) do
      {:error, :missing_org_info} ->
        raise ArgumentError, """
        InfluxDB API requires organization information.

        You can provide this information either to the client via the :org field
        or you can pass this information to `InfluxEx.query/2`.
        """

      request ->
        Request.run(request, client)
    end
  end
end
