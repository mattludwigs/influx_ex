defmodule InfluxExTest do
  use InfluxEx.DBCase

  alias InfluxEx.Me

  test "get current user information", %{client: client} do
    assert {:ok, %Me{} = me} = InfluxEx.me(client)

    assert me.name == "influx_ex"
  end
end
