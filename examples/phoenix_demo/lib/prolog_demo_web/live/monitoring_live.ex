defmodule PrologDemoWeb.MonitoringLive do
  use PrologDemoWeb, :live_view

  alias PrologDemo.CausalSessionManager
  alias PrologDemo.ConstraintSessionManager
  alias PrologDemo.PlaygroundSessionManager

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:session_stats, %{})
     |> assign(:refresh_interval, 5000)
     |> assign(:auto_refresh, true)
     |> assign(:last_update, DateTime.utc_now())
     |> refresh_all_stats()
     |> schedule_refresh()}
  end


  @impl true
  def handle_event("toggle_auto_refresh", %{"enabled" => enabled}, socket) do
    enabled_bool = enabled == "true"

    if enabled_bool do
      schedule_refresh(socket)
    else
      cancel_refresh(socket)
    end

    {:noreply, assign(socket, :auto_refresh, enabled_bool)}
  end

  @impl true
  def handle_event("refresh_stats", _params, socket) do
    {:noreply,
     socket
     |> refresh_all_stats()
     |> assign(:last_update, DateTime.utc_now())
     |> put_flash(:info, "Statistics refreshed")}
  end

  @impl true
  def handle_event("reset_stats", _params, socket) do
    # For now, just clear the displayed stats - we can't actually reset the session managers
    {:noreply,
     socket
     |> assign(:session_stats, %{})
     |> assign(:last_update, DateTime.utc_now())
     |> put_flash(:info, "Display cleared - note: session statistics are preserved")}
  end

  @impl true
  def handle_info(:refresh_stats, socket) do
    if socket.assigns.auto_refresh do
      schedule_refresh(socket)
    end

    {:noreply,
     socket
     |> refresh_all_stats()
     |> assign(:last_update, DateTime.utc_now())}
  end

  @impl true
  def handle_info({:monitoring_update, session_name, stats}, socket) do
    new_session_stats = Map.put(socket.assigns.session_stats, session_name, stats)

    {:noreply, assign(socket, :session_stats, new_session_stats)}
  end

  # Private functions

  defp refresh_all_stats(socket) do
    # Get statistics from all session managers
    causal_stats = get_session_stats("Causal Reasoning", CausalSessionManager)
    constraint_stats = get_session_stats("Constraint Solving", ConstraintSessionManager)
    playground_stats = get_session_stats("Prolog Playground", PlaygroundSessionManager)

    session_stats = %{
      "Causal" => causal_stats,
      "Constraint" => constraint_stats,
      "Playground" => playground_stats
    }

    assign(socket, :session_stats, session_stats)
  end

  defp get_session_stats(name, session_manager) do
    try do
      # Check if the session manager process is alive
      if Process.alive?(Process.whereis(session_manager)) do
        # Check if facts are loaded
        facts_loaded = session_manager.facts_loaded?()

        if facts_loaded do
          # Get monitoring summary from the session manager
          case session_manager.get_monitoring_summary() do
            {:ok, stats} ->
              Map.merge(stats, %{
                "session_name" => name,
                "facts_loaded" => facts_loaded,
                "status" => "active",
                "queries_total" => stats[:query_count] || 0,
                "last_query_time" => format_time(stats[:avg_time_ms]),
                "total_inferences" => format_number(stats[:total_inferences])
              })
            {:error, reason} ->
              %{
                "session_name" => name,
                "facts_loaded" => facts_loaded,
                "status" => "error",
                "error" => inspect(reason)
              }
          end
        else
          %{
            "session_name" => name,
            "facts_loaded" => facts_loaded,
            "status" => "inactive",
            "queries_total" => 0,
            "last_query_time" => "N/A",
            "total_inferences" => "N/A"
          }
        end
      else
        %{
          "session_name" => name,
          "facts_loaded" => false,
          "status" => "stopped",
          "error" => "Session manager not running"
        }
      end
    rescue
      error ->
        %{
          "session_name" => name,
          "facts_loaded" => false,
          "status" => "error",
          "error" => inspect(error)
        }
    end
  end

  defp schedule_refresh(socket) do
    if socket.assigns.auto_refresh do
      Process.send_after(self(), :refresh_stats, socket.assigns.refresh_interval)
    end
    socket
  end

  defp cancel_refresh(_socket) do
    # Cancel any pending refresh
    :ok
  end

  defp format_number(nil), do: "N/A"
  defp format_number(num) when is_number(num), do: :erlang.float_to_binary(num * 1.0, [:compact, decimals: 0])
  defp format_number(str), do: to_string(str)

  defp format_time(nil), do: "N/A"
  defp format_time(ms) when is_number(ms), do: "#{ms}ms"
  defp format_time(str), do: to_string(str)

  defp status_badge_class("active"), do: "bg-green-100 text-green-800"
  defp status_badge_class("inactive"), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_class("stopped"), do: "bg-red-100 text-red-800"
  defp status_badge_class("error"), do: "bg-red-100 text-red-800"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-800"

  def render_session_stats(stats) do
    assigns = %{stats: stats}

    ~H"""
    <div class="space-y-3">
      <!-- Status Badge -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Status:</span>
        <span class={[
          "px-3 py-1 text-sm font-medium rounded-full",
          status_badge_class(@stats["status"] || "unknown")
        ]}>
          <%= @stats["status"] || "unknown" %>
        </span>
      </div>

      <!-- Quick Stats Grid -->
      <div class="grid grid-cols-2 gap-4 pt-2">
        <div class="text-center">
          <div class="text-lg font-semibold text-gray-900">
            <%= @stats["queries_total"] || "0" %>
          </div>
          <div class="text-xs text-gray-500">Total Queries</div>
        </div>
        <div class="text-center">
          <div class="text-lg font-semibold text-gray-900">
            <%= @stats["total_inferences"] || "N/A" %>
          </div>
          <div class="text-xs text-gray-500">Total Inferences</div>
        </div>
      </div>

      <!-- Facts Status -->
      <div class="flex items-center justify-between pt-2 border-t border-gray-200">
        <span class="text-sm text-gray-600">Knowledge Base:</span>
        <span class={[
          "px-2 py-1 text-xs font-medium rounded",
          if(@stats["facts_loaded"], do: "bg-green-100 text-green-700", else: "bg-gray-100 text-gray-600")
        ]}>
          <%= if @stats["facts_loaded"], do: "Loaded", else: "Empty" %>
        </span>
      </div>

      <!-- Last Activity -->
      <div class="flex items-center justify-between">
        <span class="text-sm text-gray-600">Avg Query Time:</span>
        <span class="text-sm text-gray-900 font-mono">
          <%= @stats["last_query_time"] || "N/A" %>
        </span>
      </div>

      <!-- Error Display -->
      <%= if @stats["error"] do %>
        <div class="mt-3 p-3 bg-red-50 border border-red-200 rounded-md">
          <p class="text-xs text-red-700">
            <strong>Error:</strong> <%= @stats["error"] %>
          </p>
        </div>
      <% end %>
    </div>
    """
  end

end
