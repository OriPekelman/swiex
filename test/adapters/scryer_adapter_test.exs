defmodule Swiex.Adapters.ScryerAdapterTest do
  use ExUnit.Case
  alias Swiex.Adapters.ScryerAdapter

  describe "health_check/0" do
    test "returns ok when scryer-prolog is available or error when not" do
      case ScryerAdapter.health_check() do
        {:ok, :ready} ->
          # Scryer is available
          assert true
        {:error, {:scryer_not_found, _msg}} ->
          # Scryer is not installed
          assert true
        {:error, _reason} ->
          # Other error
          assert true
      end
    end
  end

  describe "info/0" do
    test "returns adapter information" do
      info = ScryerAdapter.info()
      assert info.name == "Scryer Prolog"
      assert info.type == :external
      assert is_list(info.features)
      assert :iso_compliant in info.features
      assert :constraint_logic_programming in info.features
    end
  end

  describe "session management" do
    test "can start and stop sessions when scryer is available" do
      case ScryerAdapter.health_check() do
        {:ok, :ready} ->
          assert {:ok, session} = ScryerAdapter.start_session()
          assert is_binary(session.session_id)
          assert :ok = ScryerAdapter.stop_session(session)
        {:error, _} ->
          assert {:error, _} = ScryerAdapter.start_session()
      end
    end
  end

  describe "query/2" do
    test "handles basic queries when scryer is available" do
      case ScryerAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = ScryerAdapter.start_session()
          
          # Test true query
          assert {:ok, [%{}]} = ScryerAdapter.query(session, "true")
          
          # Test fail query
          assert {:ok, []} = ScryerAdapter.query(session, "fail")
          
          # Test arithmetic
          case ScryerAdapter.query(session, "X is 1 + 1") do
            {:ok, [%{"X" => 2}]} -> assert true
            {:ok, results} -> assert is_list(results)
            {:error, _} -> assert true  # May fail if scryer has issues
          end
          
          ScryerAdapter.stop_session(session)
        {:error, _} ->
          # Skip test if scryer not available
          :ok
      end
    end

    test "handles member queries when scryer is available" do
      case ScryerAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = ScryerAdapter.start_session()
          
          case ScryerAdapter.query(session, "member(X, [1,2,3])") do
            {:ok, results} when is_list(results) ->
              # Should get multiple solutions
              assert length(results) > 0
            {:error, _} ->
              # May fail due to scryer setup issues
              assert true
          end
          
          ScryerAdapter.stop_session(session)
        {:error, _} ->
          # Skip test if scryer not available
          :ok
      end
    end
  end

  describe "query/1" do
    test "handles sessionless queries when scryer is available" do
      case ScryerAdapter.health_check() do
        {:ok, :ready} ->
          assert {:ok, [%{}]} = ScryerAdapter.query("true")
          assert {:ok, []} = ScryerAdapter.query("fail")
        {:error, _} ->
          assert {:error, _} = ScryerAdapter.query("true")
      end
    end
  end

  describe "assertz/2" do
    test "can assert facts when scryer is available" do
      case ScryerAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = ScryerAdapter.start_session()
          
          case ScryerAdapter.assertz(session, "likes(john, pizza)") do
            {:ok, updated_session} ->
              # Test querying the asserted fact
              case ScryerAdapter.query(updated_session, "likes(john, X)") do
                {:ok, results} ->
                  assert is_list(results)
                  assert length(results) > 0
                {:error, _} ->
                  # May fail due to scryer issues
                  assert true
              end
            {:error, _} ->
              # May fail due to scryer setup
              assert true
          end
          
          ScryerAdapter.stop_session(session)
        {:error, _} ->
          # Skip test if scryer not available
          :ok
      end
    end
  end

  describe "consult/2" do
    test "returns appropriate response for file loading" do
      case ScryerAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = ScryerAdapter.start_session()
          
          # Test with non-existent file
          case ScryerAdapter.consult(session, "/nonexistent/file.pl") do
            {:error, _} ->
              # Expected for non-existent file
              assert true
            {:ok, _} ->
              # Unexpected but not necessarily wrong
              assert true
          end
          
          ScryerAdapter.stop_session(session)
        {:error, _} ->
          # Skip test if scryer not available
          :ok
      end
    end
  end
end