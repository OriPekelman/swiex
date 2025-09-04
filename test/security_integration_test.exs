defmodule Swiex.SecurityIntegrationTest do
  use ExUnit.Case
  alias Swiex.MQI

  describe "security integration with MQI" do
    test "rejects dangerous queries" do
      assert {:error, {:security_error, :potentially_dangerous_query}} =
        MQI.query("halt")

      assert {:error, {:security_error, :potentially_dangerous_query}} =
        MQI.query("shell(cmd)")

      assert {:error, {:security_error, :potentially_dangerous_query}} =
        MQI.query("system(ls)")
    end

    test "rejects queries that are too large" do
      large_query = String.duplicate("member(X, [1,2,3]), ", 1000)
      assert {:error, {:security_error, :query_too_large}} =
        MQI.query(large_query)
    end

    test "rejects dangerous assertz clauses" do
      assert {:error, {:security_error, :potentially_dangerous_query}} =
        MQI.assertz("halt")

      assert {:error, {:security_error, :potentially_dangerous_query}} =
        MQI.assertz("shell(cmd)")
    end

    test "accepts safe queries" do
      assert {:ok, [%{"X" => 1}, %{"X" => 2}, %{"X" => 3}]} =
        MQI.query("member(X, [1,2,3])")
    end

    test "accepts safe assertz clauses" do
      assert {:ok, _} = MQI.assertz("test_fact(42)")
      # Clean up
      MQI.query("retract(test_fact(42))")
    end
  end
end
