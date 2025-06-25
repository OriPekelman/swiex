defmodule Swiex.MQIConnectTest do
  use ExUnit.Case

  test "can connect and authenticate to MQI server" do
    assert {:ok, _} = Swiex.MQI.query("true")
  end
end
