defmodule Swiex.Adapters.ErlogAdapterTest do
  use ExUnit.Case
  alias Swiex.Adapters.ErlogAdapter

  describe "health_check/0" do
    test "returns ok when erlog is available" do
      case Code.ensure_loaded(:erlog) do
        {:module, :erlog} ->
          assert {:ok, :ready} = ErlogAdapter.health_check()
        {:error, :nofile} ->
          assert {:error, _} = ErlogAdapter.health_check()
      end
    end
  end

  describe "info/0" do
    test "returns adapter information" do
      info = ErlogAdapter.info()
      assert info.name == "Erlog"
      assert info.type == :embedded
      assert is_list(info.features)
    end
  end

  describe "session management" do
    test "can start and stop sessions" do
      case ErlogAdapter.health_check() do
        {:ok, :ready} ->
          assert {:ok, session} = ErlogAdapter.start_session()
          assert :ok = ErlogAdapter.stop_session(session)
        {:error, _} ->
          assert {:error, _} = ErlogAdapter.start_session()
      end
    end
  end

  describe "query/2" do
    test "handles true query" do
      case ErlogAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = ErlogAdapter.start_session()
          assert {:ok, [%{}]} = ErlogAdapter.query(session, "true")
          ErlogAdapter.stop_session(session)
        {:error, _} ->
          # Skip test if erlog not available
          :ok
      end
    end

    test "handles fail query" do
      case ErlogAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = ErlogAdapter.start_session()
          assert {:ok, []} = ErlogAdapter.query(session, "fail")
          ErlogAdapter.stop_session(session)
        {:error, _} ->
          # Skip test if erlog not available
          :ok
      end
    end

    test "returns error for unsupported queries" do
      case ErlogAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = ErlogAdapter.start_session()
          assert {:error, :unsupported} = ErlogAdapter.query(session, "member(X, [1,2,3])")
          ErlogAdapter.stop_session(session)
        {:error, _} ->
          # Skip test if erlog not available
          :ok
      end
    end
  end

  describe "query/1" do
    test "handles sessionless queries" do
      case ErlogAdapter.health_check() do
        {:ok, :ready} ->
          assert {:ok, [%{}]} = ErlogAdapter.query("true")
          assert {:ok, []} = ErlogAdapter.query("fail")
          assert {:error, :unsupported} = ErlogAdapter.query("complex_query")
        {:error, _} ->
          # Skip test if erlog not available
          :ok
      end
    end
  end

  describe "assertz/2" do
    test "returns error for unsupported operation" do
      case ErlogAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = ErlogAdapter.start_session()
          assert {:error, :unsupported} = ErlogAdapter.assertz(session, "likes(john, pizza)")
          ErlogAdapter.stop_session(session)
        {:error, _} ->
          # Skip test if erlog not available
          :ok
      end
    end
  end

  describe "consult/2" do
    test "returns error for unsupported operation" do
      case ErlogAdapter.health_check() do
        {:ok, :ready} ->
          {:ok, session} = ErlogAdapter.start_session()
          assert {:error, :unsupported} = ErlogAdapter.consult(session, "file.pl")
          ErlogAdapter.stop_session(session)
        {:error, _} ->
          # Skip test if erlog not available
          :ok
      end
    end
  end
end