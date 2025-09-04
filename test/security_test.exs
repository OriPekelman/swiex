defmodule Swiex.SecurityTest do
  use ExUnit.Case
  alias Swiex.Security

  describe "sanitize_query/1" do
    test "accepts valid queries" do
      assert {:ok, "member(X, [1,2,3])"} = Security.sanitize_query("member(X, [1,2,3])")
      assert {:ok, "factorial(5, Result)"} = Security.sanitize_query("factorial(5, Result)")
    end

    test "rejects queries that are too large" do
      large_query = String.duplicate("a", 10_001)
      assert {:error, :query_too_large} = Security.sanitize_query(large_query)
    end

    test "rejects dangerous queries" do
      assert {:error, :potentially_dangerous_query} = Security.sanitize_query("halt")
      assert {:error, :potentially_dangerous_query} = Security.sanitize_query("shell(cmd)")
      assert {:error, :potentially_dangerous_query} = Security.sanitize_query("system(ls)")
      assert {:error, :potentially_dangerous_query} = Security.sanitize_query("exec(rm -rf)")
    end

    test "rejects non-string queries" do
      assert {:error, :invalid_query_type} = Security.sanitize_query(123)
      assert {:error, :invalid_query_type} = Security.sanitize_query([1, 2, 3])
    end

    test "escapes special characters" do
      assert {:ok, "I\\'m a \\\"string\\\" with \\\\backslashes"} =
        Security.sanitize_query("I'm a \"string\" with \\backslashes")
    end
  end

  describe "validate_query/1" do
    test "validates safe queries" do
      assert :ok = Security.validate_query("member(X, [1,2,3])")
      assert :ok = Security.validate_query("factorial(5, Result)")
    end

    test "rejects unsafe queries" do
      assert {:error, :potentially_dangerous_query} = Security.validate_query("halt")
      assert {:error, :query_too_large} = Security.validate_query(String.duplicate("a", 10_001))
    end
  end

  describe "escape_query/1" do
    test "escapes single quotes" do
      assert "I\\'m escaped" = Security.escape_query("I'm escaped")
    end

    test "escapes double quotes" do
      assert "\\\"quoted\\\"" = Security.escape_query("\"quoted\"")
    end

    test "escapes backslashes" do
      assert "path\\\\to\\\\file" = Security.escape_query("path\\to\\file")
    end

    test "handles multiple escapes" do
      assert "I\\'m \\\"quoted\\\" with \\\\backslashes" =
        Security.escape_query("I'm \"quoted\" with \\backslashes")
    end
  end
end
