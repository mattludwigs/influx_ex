defmodule InfluxEx.API.Data do
  @moduledoc false

  alias InfluxEx.HTTP.Request
  alias InfluxEx.{Bucket, Org, Point, TableRow}

  @doc """
  Write points to InfluxDB
  """
  @spec write(
          Org.name(),
          Bucket.name(),
          Point.t() | [Point.t()],
          System.time_unit()
        ) :: Request.t()
  def write(org_name, bucket, point_or_points, precision) do
    payload = make_write_payload(point_or_points)
    query = add_precision(%{org: org_name, bucket: bucket}, precision)

    Request.new("/write",
      payload: payload,
      query_params: query,
      method: :post,
      handler: &handle_write_response/1
    )
  end

  defp handle_write_response(%{body: ""}) do
    :ok
  end

  defp make_write_payload(points) when is_list(points) do
    points
    |> Enum.reduce("", fn point, payload ->
      payload <> Point.to_line_protocol(point) <> "\n"
    end)
    |> String.trim("\n")
  end

  defp make_write_payload(point) do
    Point.to_line_protocol(point)
  end

  defp add_precision(query, :nanosecond) do
    Map.put(query, :precision, "ns")
  end

  defp add_precision(query, :microsecond) do
    Map.put(query, :precision, "us")
  end

  defp add_precision(query, :millisecond) do
    Map.put(query, :precision, "ms")
  end

  defp add_precision(query, :second) do
    Map.put(query, :precision, "s")
  end

  @doc """
  Query InfluxDB request
  """
  @spec query(binary(), [InfluxEx.query_opt()]) ::
          Request.t() | {:error, :missing_org_info}
  def query(query, opts \\ []) do
    case make_query_params_for_query(opts) do
      {:ok, api_query_params} ->
        "/query"
        |> Request.new(
          payload: query,
          method: :post,
          query_params: api_query_params,
          handler: &handle_query_response/1
        )

      error ->
        error
    end
  end

  defp make_query_params_for_query(opts) do
    query_param_opts = Keyword.take(opts, [:org, :org_id])

    params =
      Enum.reduce(query_param_opts, %{}, fn {k, v}, query_params ->
        Map.put(query_params, k, v)
      end)

    if Map.get(params, :org) || Map.get(params, :org_id) do
      {:ok, params}
    else
      {:error, :missing_org_info}
    end
  end

  defp handle_query_response(%{body: [[""]]}) do
    {:ok, %{}}
  end

  defp handle_query_response(%{body: body}) do
    [headers | rows] = body

    tags = tags_from_headers(headers)

    result =
      rows
      |> Enum.filter(fn r -> r != [""] end)
      |> Enum.group_by(fn [_, _, table | _rest] -> table end)
      |> Enum.reduce(%{}, fn {table_idx, csv_rows}, table ->
        rows = Enum.map(csv_rows, &TableRow.from_csv_row(&1, tags))
        {idx, _} = Integer.parse(table_idx)
        Map.put(table, idx, rows)
      end)

    {:ok, result}
  end

  defp tags_from_headers([
         _,
         _result_name,
         _table,
         _start,
         _stop,
         _time,
         _value,
         _field,
         _measurement | tags
       ]) do
    tags
  end

  @doc """
  Query for working with schema information for a bucket
  """
  @spec schema_query(binary(), [InfluxEx.query_opt()]) ::
          Request.t() | {:error, :missing_org_info}
  def schema_query(query, opts \\ []) do
    case make_query_params_for_query(opts) do
      {:ok, api_query_params} ->
        "/query"
        |> Request.new(
          payload: query,
          method: :post,
          query_params: api_query_params,
          handler: &handle_schema_query_response/1
        )

      error ->
        error
    end
  end

  defp handle_schema_query_response(%{body: body}) do
    [_headers | rows] = body

    result =
      Enum.reduce(rows, [], fn
        [""], measurements -> measurements
        [_, _result, _table, value], measurements -> measurements ++ [value]
      end)

    {:ok, result}
  end
end
