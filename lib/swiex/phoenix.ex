defmodule Swiex.Phoenix do
  @moduledoc """
  Phoenix integration for Swiex.

  This module provides Phoenix-specific functionality for using Prolog in web applications,
  including hot-code loading and web-friendly query interfaces.
  """

  @doc """
  Define Prolog code that can be hot-reloaded in Phoenix development.
  """
  defmacro prolog_controller(do: block) do
    quote do
      use Phoenix.Controller
      import Swiex.Macros

      # Enable hot-code loading for Prolog definitions
      if Mix.env() == :dev do
        Swiex.Phoenix.enable_hot_reload()
      end

      unquote(block)
    end
  end

  @doc """
  Create a Phoenix LiveView with Prolog integration.
  """
  defmacro prolog_live_view(do: block) do
    quote do
      use Phoenix.LiveView
      import Swiex.Macros

      # Enable hot-code loading for Prolog definitions
      if Mix.env() == :dev do
        Swiex.Phoenix.enable_hot_reload()
      end

      unquote(block)
    end
  end

  @doc """
  Enable hot-code reloading for Prolog definitions.
  """
  def enable_hot_reload do
    # Watch for changes in Prolog files
    if Code.ensure_loaded?(FileSystem) and function_exported?(FileSystem, :subscribe, 1) do
      FileSystem.subscribe(self())
      # Handle file changes
      Task.start(fn ->
        handle_file_changes()
      end)
    end
  end

  @doc """
  Create a REST API endpoint for Prolog queries.
  """
  def create_prolog_endpoint(_router, path \\ "/api/prolog") do
    quote do
      post unquote(path), PrologController, :query
      get unquote(path <> "/health"), PrologController, :health
    end
  end

  @doc """
  Create a WebSocket endpoint for real-time Prolog queries.
  """
  def create_prolog_socket(_router, path \\ "/socket/prolog") do
    quote do
      socket unquote(path), Swiex.Phoenix.Socket,
        websocket: true,
        longpoll: false
    end
  end

  # Private functions

  defp handle_file_changes do
    receive do
      {:file_event, _pid, {path, _events}} ->
        if String.ends_with?(path, ".pl") do
          reload_prolog_file(path)
        end
        handle_file_changes()

      {:file_event, _pid, :stop} ->
        :ok
    end
  end

  defp reload_prolog_file(path) do
    case File.read(path) do
      {:ok, content} ->
        Swiex.load_code(content)
        IO.puts("Reloaded Prolog file: #{path}")

      {:error, reason} ->
        IO.puts("Failed to reload Prolog file #{path}: #{reason}")
    end
  end
end

# Only define Phoenix-specific modules if Phoenix is available
if Code.ensure_loaded(Phoenix.Socket) == {:module, Phoenix.Socket} do
  defmodule Swiex.Phoenix.Socket do
    @moduledoc """
    WebSocket handler for real-time Prolog queries.
    """

    use Phoenix.Socket
    import Swiex.Macros

    channel "prolog:*", Swiex.Phoenix.Channel

    def connect(_params, socket, _connect_info) do
      {:ok, socket}
    end

    def id(_socket), do: nil
  end

  defmodule Swiex.Phoenix.Channel do
    @moduledoc """
    Phoenix channel for handling Prolog queries over WebSocket.
    """

    use Phoenix.Channel
    import Swiex.Macros

    def join("prolog:query", _message, socket) do
      {:ok, socket}
    end

    def handle_in("execute_query", %{"query" => query}, socket) do
      case Swiex.query(query) do
        {:ok, results} ->
          push(socket, "query_result", %{results: results})
          {:noreply, socket}

        {:error, reason} ->
          push(socket, "query_error", %{error: reason})
          {:noreply, socket}
      end
    end

    def handle_in("execute_async_query", %{"query" => query}, socket) do
      case Swiex.query_async(query) do
        {:ok, query_id} ->
          push(socket, "async_query_started", %{query_id: query_id})
          {:noreply, socket}

        {:error, reason} ->
          push(socket, "query_error", %{error: reason})
          {:noreply, socket}
      end
    end

    def handle_in("get_async_result", %{"query_id" => query_id}, socket) do
      case Swiex.get_async_result(query_id) do
        {:ok, results} ->
          push(socket, "async_query_result", %{query_id: query_id, results: results})
          {:noreply, socket}

        {:error, reason} ->
          push(socket, "query_error", %{error: reason})
          {:noreply, socket}
      end
    end
  end
end
