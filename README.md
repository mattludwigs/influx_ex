# InfluxEx

Library for working with the [v2.X InfluxDB API](https://docs.influxdata.com/influxdb/v2.2/api/).

## Installation

```elixir
def deps do
  [
    {:influx_ex, "~> 0.1.0"},
    # below are optional deps but InfluxEx will try to use them as defaults so
    # if you are okay with these defaults ensure they are added in your deps as
    # well.
    {:mojito, "~> 0.7.11"},
    {:jason, "~> 1.0"},
    {:nimble_csv, "~> 1.0"}
  ]
end
```

## Setup

To get started quickly you need to add these optional dependencies to your deps:

```elixir
{:mojito, "~> 0.7.11"},
{:jason, "~> 1.0"},
{:nimble_csv, "~> 1.0"}
```

After adding these to your dependencies run `mix deps.get`

Then run `docker-compose up -d` to start a InfluxDB container which will be
reachable at `http://localhost:8086`.

Next lets check the current user but running `iex -S mix` and typing:

```elixir
client = InfluxEx.Client.new("devtoken")

InfluxEx.me(client)
{:ok, %InfluxEx.Me{}}
```

If you don't want to use the default libraries for HTTP, JSON, and CSV see the
configuration section below for more information.

If you're using `docker-compose`, the development token is `"devtoken"` and
during tests the token is `"testtoken"`.

## Client

`InfluxEx` does not provide a process based client. This provided the most
flexibility to consuming applications to decide if a process is needed or not
for managing state.

If you want the client to be in a process here's a stub of what that might look
like to get you started:

```elixir
defmodule MyApp.InfluxClient do
  use GenServer

  alias InfluxEx.{Client, Orgs}

  @type arg() ::
          {:token, InfluxEx.token()}
          | {:org, Orgs.name()}
          | {:org_id, Orgs.id()}
          | {:port, :inet.port_number()}
          | {:host, :inet.hostname()}

  @doc """
  Start the client
  """
  @spec start_link([arg()]) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(args) do
    # required args
    token = Keyword.fetch!(args, :token)
    org = Keyword.fetch!(args, :org)
    org_id = Keyword.fetch!(args, :org_id)

    # optional args
    port = Keyword.get(args, :port) || 8086
    host = Keyword.get(args, :host) || "http://localhost"

    client = Client.new(token, port: port, host: host, org: org, org_id: org_id)

    {:ok, %{client: client}}
  end
end

```

## Configuration

### HTTP Client

The InfluxDB API uses the HTTP protocol. By default `InfluxEx` will try to use
`Mojito` to make HTTP request. If you want to use `Mojito` you will need to add
it to your deps in your `mix.exs` file.

```elixir
{:mojito, "~> 0.7.11"},
```

If you use a different HTTP library you can provide the client with a module
that implements the `InfluxEx.HTTP` behaviour that wraps your preferred HTTP
library.

```elixir
my_client = InfluxEx.Client.new("mytoken", http_client: MyHTTPClient)
```

### JSON Library

The InfluxDB API using JSON format to communicate data between the client and
server. InfluxEx needs away to encode and decode the JSON payloads to and from
Elixir data types. By default InfluxEx will try to use the `Jason` library. To
use this default you need to add `:jason` to you deps in your `mix.exs`:

```elixir
{:jason, "~> 1.0"},
```

If you want to use a different JSON library pass a module name into the
`:json_library` option when creating a client. Ensure that the module
implements the `InfluxEx.JSONLibrary` behaviour.

```elixir
InfluxEx.Client.new("mytoken", json_library: MyJSONLibrary)
```

### CSV Library

For some API calls the InfluxDB API requires working with the CSV content type.
By default `InfluxEx` will try to use the `:nimble_csv` library. If you are
okay with default you need to add this to your `mix.exs` file:

```elixir
{:nimble_csv, "~> 1.0"}
```

If you want to use a different decoder you can supply that to
`InfluxEx.Client.new/2`.

If you want to use a different library you can supply a module that implements
`InfluxEx.CSVLibrary` to your client using the `:csv_library` option:

```elixir
InfluxEx.Client.new("mytoken", csv_library: MyCSVLibrary)
```

One important note about using a custom CSV library is the `parse_string/1`
callback implementation needs to keep the CSV headers as InfluxEx needs them to
ensure it handles tag names and values correctly.
