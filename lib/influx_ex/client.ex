defmodule InfluxEx.Client do
  @moduledoc """
  The primary configuration to talking with InfluxDB

  The client allows for customizing how JSON, CSV, and HTTP are all handled. By
  default the client will try to use `:jason` for JSON, `:nimble_csv` for CSV,
  and `:mojito` for HTTP requests.

  To ensure all these libraries are available add these lines to your deps in
  your `mix.exs`:

  ```elixir
  {:mojito, "~> 0.7.11"},
  {:jason, "~> 1.0"},
  {:nimble_csv, "~> 1.0"}
  ```

  If you prefer to use other libraries you can customize these options.

  The client is not processed based and the consuming application will need
  provide any process architecture to manage client state.

  The reason for this is to allow maximal flexibility around how a consumer will
  want to call the InfluxEx functions and allow the user to decided if a process
  is necessary.

  ### JSON Library

  By default `Influx.Client` will default to using `Jason.decode/1` as the
  decode function. You can pass an `InfluxEx.decoder()` function to the
  `:json_decoder` field when creating a new client.

  By default `Influx.Client` will use the `:jason` library to handle JSON
  encoding and decoding. If you want to use a different solution you can provide
  a module that implements the `InfluxEx.JSONLibrary` behaviour to the
  `:json_library` option to `InfluxEx.Client.new/2`

  ```elixir
  InfluxEx.Client.new("mytoken", json_library: MyJSONLib)
  ```

  ### CSV library

  By default `Influx.Client` will use the `:nimble_csv` library as the CSV
  library. If you want to provide your own library you can pass the name name
  of your module, which implements the `InfluxEx.CSVLibrary` behaviour to the
  `:csv_library` option when calling `InfluxEx.Client.new/2`.

  It's important to keep the CSV headers, so if your custom function tries to
  skip headers you might have to wrap the function in order to pass options to
  your decoder to keep the headers.

  ```elixir
  InfluxEx.Client.new("mytoken", csv_library: MyCSVLibrary)
  ```

  ### HTTP library

  InfluxEx provides a behaviour for supporting different HTTP clients. You can
  wrap your chosen HTTP client in the `InfluxEx.HTTP` behaviour and configure
  the client to use your implementation. By default `InfluxEx` using mojito.

  ```elixir
  InfluxEx.Client.new("mytoken", http_client: MyHTTPLibraryImplementation)
  ```
  """

  alias InfluxEx.{HTTP, Org}

  @typedoc """
  Client data structure

  * `:token` - the API token provided by InfluxDB (required)
  * `:host` - the host name for the InfluxDB server, defaults to localhost
  * `:port` - the port number for the InfluxDB server, defaults to `8086`
  * `:json_library` - a module that provides functionality for encoding and
    decoding JSON
  * `:csv_library` - a module that implements the `InfluxEx.CSVLibrary`
  * `:http_client` - a module that implements the `InfluxEx.HTTP` behaviour, by
    default this will try to use the `InfluxEx.HTTP.Mojito` module.
  * `:org` - the name of the organization inside of the InfluxDB server.
  * `:org_id` the org id of the organization inside of the InfluxDB server.
  """
  @type t() :: %__MODULE__{
          token: InfluxEx.token(),
          host: :inet.hostname(),
          port: integer(),
          json_library: InfluxEx.JSONLibrary.t(),
          csv_library: InfluxEx.CSVLibrary.t(),
          http_client: HTTP.t(),
          org: Org.name() | nil,
          org_id: Org.id() | nil
        }

  defstruct token: nil,
            host: nil,
            port: nil,
            json_library: nil,
            csv_library: nil,
            http_client: nil,
            org: nil,
            org_id: nil

  @type opt() ::
          {:host, :inet.hostname()}
          | {:port, integer()}
          | {:json_library, InfluxEx.JSONLibrary.t()}
          | {:csv_library, InfluxEx.CSVLibrary.t()}
          | {:http_client, HTTP.t()}
          | {:org, Org.name()}
          | {:org_id, Org.id()}

  @spec new(InfluxEx.token(), [opt()]) :: t()
  def new(token, opts \\ []) do
    host = opts[:host] || "http://localhost"
    port = opts[:port] || 8086
    json = opts[:json_library] || Jason
    csv_lib = opts[:csv_library] || InfluxEx.CSV
    org = opts[:org]
    org_id = opts[:org_id]
    http_client = opts[:http_client] || HTTP.Mojito

    %__MODULE__{
      token: token,
      host: host,
      port: port,
      json_library: json,
      csv_library: csv_lib,
      org: org,
      org_id: org_id,
      http_client: http_client
    }
  end
end
