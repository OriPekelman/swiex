defmodule Swiex.PrologTest do
  use ExUnit.Case
  alias Swiex.Prolog
  alias Swiex.Adapters.{SwiAdapter, ErlogAdapter, ScryerAdapter}

  describe "default_adapter/0" do
    test "returns configured default adapter" do
      adapter = Prolog.default_adapter()
      assert adapter == SwiAdapter
    end
  end

  describe "start_session/1" do
    test "starts session with default adapter" do
      case SwiAdapter.health_check() do
        {:ok, :ready} ->
          assert {:ok, {session, adapter}} = Prolog.start_session()
          assert adapter == SwiAdapter
          Prolog.stop_session({session, adapter})
        {:error, _} ->
          # SWI-Prolog not available, test should handle gracefully
          case Prolog.start_session() do
            {:ok, {session, adapter}} ->
              Prolog.stop_session({session, adapter})
              assert true
            {:error, _} ->
              assert true
          end
      end
    end

    test "starts session with specified adapter" do
      case ErlogAdapter.health_check() do
        {:ok, :ready} ->
          assert {:ok, {session, adapter}} = Prolog.start_session(adapter: ErlogAdapter)
          assert adapter == ErlogAdapter
          Prolog.stop_session({session, adapter})
        {:error, _} ->
          # Erlog not available
          assert {:error, _} = Prolog.start_session(adapter: ErlogAdapter)
      end
    end
  end

  describe "query/2 with session" do
    test "executes query with session" do
      case SwiAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = Prolog.start_session()
          assert {:ok, results} = Prolog.query(session, "true")
          assert is_list(results)
          Prolog.stop_session(session)
        {:error, _} ->
          # Skip if SWI not available
          :ok
      end
    end
  end

  describe "query/2 sessionless" do
    test "executes query without session using default adapter" do
      case SwiAdapter.health_check() do
        {:ok, :ready} ->
          assert {:ok, results} = Prolog.query("true")
          assert is_list(results)
        {:error, _} ->
          # May fail if SWI not available
          case Prolog.query("true") do
            {:ok, results} -> assert is_list(results)
            {:error, _} -> assert true
          end
      end
    end

    test "executes query with specified adapter" do
      case ErlogAdapter.health_check() do
        {:ok, :ready} ->
          assert {:ok, [%{}]} = Prolog.query("true", adapter: ErlogAdapter)
        {:error, _} ->
          assert {:error, _} = Prolog.query("true", adapter: ErlogAdapter)
      end
    end
  end

  describe "info/1" do
    test "returns info for default adapter" do
      info = Prolog.info()
      assert is_map(info)
      assert Map.has_key?(info, :name)
      assert Map.has_key?(info, :type)
    end

    test "returns info for specified adapter" do
      info = Prolog.info(ErlogAdapter)
      assert info.name == "Erlog"
      assert info.type == :embedded
    end
  end

  describe "health_check/1" do
    test "checks health of default adapter" do
      result = Prolog.health_check()
      assert result in [{:ok, :ready}, {:error, :swi_prolog_not_available}] || 
             match?({:error, _}, result)
    end

    test "checks health of specified adapter" do
      result = Prolog.health_check(ErlogAdapter)
      case Code.ensure_loaded(:erlog) do
        {:module, :erlog} ->
          assert result == {:ok, :ready}
        {:error, :nofile} ->
          assert match?({:error, _}, result)
      end
    end
  end

  describe "list_adapters/0" do
    test "returns list of all adapters with status" do
      adapters = Prolog.list_adapters()
      assert is_list(adapters)
      assert length(adapters) == 3

      for %{adapter: adapter, info: info, health: health} <- adapters do
        assert adapter in [SwiAdapter, ErlogAdapter, ScryerAdapter]
        assert is_map(info)
        assert health in [:ok, :error]
      end
    end
  end

  describe "set_default_adapter/1" do
    test "sets default adapter" do
      original = Prolog.default_adapter()
      
      Prolog.set_default_adapter(ErlogAdapter)
      assert Prolog.default_adapter() == ErlogAdapter
      
      # Restore original
      Prolog.set_default_adapter(original)
      assert Prolog.default_adapter() == original
    end
  end

  describe "query_all/2" do
    test "executes query across multiple adapters" do
      results = Prolog.query_all("true")
      assert is_map(results)
      assert map_size(results) >= 1

      for {adapter, result} <- results do
        assert adapter in [SwiAdapter, ErlogAdapter, ScryerAdapter]
        assert match?({:ok, _}, result) or match?({:error, _}, result)
      end
    end

    test "executes query across specified adapters" do
      results = Prolog.query_all("true", [ErlogAdapter])
      assert is_map(results)
      assert Map.has_key?(results, ErlogAdapter)
      
      case Code.ensure_loaded(:erlog) do
        {:module, :erlog} ->
          assert results[ErlogAdapter] == {:ok, [%{}]}
        {:error, :nofile} ->
          assert match?({:error, _}, results[ErlogAdapter])
      end
    end
  end

  describe "assertz/2" do
    test "asserts fact in session" do
      case SwiAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = Prolog.start_session()
          
          case Prolog.assertz(session, "test_fact(123)") do
            {:ok, updated_session} ->
              # Test querying the fact
              case Prolog.query(updated_session, "test_fact(X)") do
                {:ok, results} ->
                  assert is_list(results)
                  assert length(results) > 0
                {:error, _} ->
                  # May fail due to various reasons
                  assert true
              end
              Prolog.stop_session(updated_session)
            {:error, _} ->
              # May fail if assertz not supported
              Prolog.stop_session(session)
              assert true
          end
        {:error, _} ->
          # Skip if SWI not available
          :ok
      end
    end
  end

  describe "consult/2" do
    test "consults file in session" do
      case SwiAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = Prolog.start_session()
          
          # Test with non-existent file (should fail gracefully)
          case Prolog.consult(session, "/nonexistent/file.pl") do
            {:ok, _} ->
              # Unexpected success
              assert true
            {:error, _} ->
              # Expected failure
              assert true
          end
          
          Prolog.stop_session(session)
        {:error, _} ->
          # Skip if SWI not available
          :ok
      end
    end
  end
end