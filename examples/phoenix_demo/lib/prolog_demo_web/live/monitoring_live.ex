defmodule PrologDemoWeb.MonitoringLive do
  use PrologDemoWeb, :live_view

  alias PrologDemo.CausalSessionManager
  alias PrologDemo.ConstraintSessionManager
  alias PrologDemo.PlaygroundSessionManager

  @impl true
  def mount(_params, _session, socket) do
    # Initialize monitoring state
    monitoring_state = Swiex.Monitoring.init(debug_enabled: false, rate_limit_ms: 1000)

    {:ok,
     socket
     |> assign(:monitoring_state, monitoring_state)
     |> assign(:session_stats, %{})
     |> assign(:debug_enabled, false)
     |> assign(:rate_limit_ms, 1000)
     |> assign(:refresh_interval, 5000)
     |> assign(:auto_refresh, false)
     |> schedule_refresh()}
  end

  @impl true
  def handle_event("toggle_debug", %{"enabled" => enabled}, socket) do
    enabled_bool = enabled == "true"
    new_state = Swiex.Monitoring.set_debug_enabled(socket.assigns.monitoring_state, enabled_bool)

    {:noreply,
     socket
     |> assign(:monitoring_state, new_state)
     |> assign(:debug_enabled, enabled_bool)
     |> put_flash(:info, "Debug #{if enabled_bool, do: "enabled", else: "disabled"}")}
  end

  @impl true
  def handle_event("set_rate_limit", %{"rate_limit" => rate_limit}, socket) do
    rate_limit_int = String.to_integer(rate_limit)
    new_state = Swiex.Monitoring.set_rate_limit(socket.assigns.monitoring_state, rate_limit_int)

    {:noreply,
     socket
     |> assign(:monitoring_state, new_state)
     |> assign(:rate_limit_ms, rate_limit_int)
     |> put_flash(:info, "Rate limit set to #{rate_limit_int}ms")}
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
    {:noreply, refresh_all_stats(socket)}
  end

  @impl true
  def handle_event("reset_stats", _params, socket) do
    new_state = Swiex.Monitoring.reset_stats(socket.assigns.monitoring_state)

    {:noreply,
     socket
     |> assign(:monitoring_state, new_state)
     |> assign(:session_stats, %{})
     |> put_flash(:info, "Statistics reset")}
  end

  @impl true
  def handle_info(:refresh_stats, socket) do
    if socket.assigns.auto_refresh do
      schedule_refresh(socket)
    end

    {:noreply, refresh_all_stats(socket)}
  end

  @impl true
  def handle_info({:monitoring_update, session_name, stats}, socket) do
    new_session_stats = Map.put(socket.assigns.session_stats, session_name, stats)

    {:noreply, assign(socket, :session_stats, new_session_stats)}
  end

  # Private functions

  defp refresh_all_stats(socket) do
    # Get statistics from all session managers
    causal_stats = get_session_stats("Causal", CausalSessionManager)
    constraint_stats = get_session_stats("Constraint", ConstraintSessionManager)
    playground_stats = get_session_stats("Playground", PlaygroundSessionManager)

    # Get overall monitoring summary
    monitoring_summary = Swiex.Monitoring.get_summary(socket.assigns.monitoring_state)

    session_stats = %{
      "Causal" => causal_stats,
      "Constraint" => constraint_stats,
      "Playground" => playground_stats,
      "Overall" => monitoring_summary
    }

    assign(socket, :session_stats, session_stats)
  end

  defp get_session_stats(name, session_manager) do
    try do
      # Check if facts are loaded
      facts_loaded = session_manager.facts_loaded?()

      if facts_loaded do
        # Get basic statistics
        case session_manager.get_statistics() do
          {:ok, stats} ->
            Map.merge(stats, %{
              "session_name" => name,
              "facts_loaded" => facts_loaded,
              "status" => "active"
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
          "status" => "inactive"
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
  defp format_number(num) when is_number(num), do: Number.Delimit.number_to_delimited(num)
  defp format_number(str), do: to_string(str)

  defp format_time(nil), do: "N/A"
  defp format_time(ms) when is_number(ms), do: "#{ms}ms"
  defp format_time(str), do: to_string(str)

  defp status_badge_class("active"), do: "bg-green-100 text-green-800"
  defp status_badge_class("inactive"), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_class("error"), do: "bg-red-100 text-red-800"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-800"

  def render_session_stats(stats) do
    assigns = %{stats: stats}

    ~H"""
    <div class="space-y-3">
      <!-- Status -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Status:</span>
        <span class={[
          "px-2 py-1 text-xs font-medium rounded-full",
          status_badge_class(@stats["status"] || "unknown")
        ]}>
          <%= @stats["status"] || "unknown" %>
        </span>
      </div>

      <!-- Facts Loaded -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Facts Loaded:</span>
        <span class={[
          "px-2 py-1 text-xs font-medium rounded-full",
          if(@stats["facts_loaded"], do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800")
        ]}>
          <%= if @stats["facts_loaded"], do: "Yes", else: "No" %>
        </span>
      </div>

      <!-- Query Count -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Query Count:</span>
        <span class="text-sm text-gray-900"><%= format_number(@stats["query_count"]) %></span>
      </div>

      <!-- Total Inferences -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Total Inferences:</span>
        <span class="text-sm text-gray-900"><%= format_number(@stats["total_inferences"]) %></span>
      </div>

      <!-- Total Time -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Total Time:</span>
        <span class="text-sm text-gray-900"><%= format_time(@stats["total_time_ms"]) %></span>
      </div>

      <!-- Average Time -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Avg Time:</span>
        <span class="text-sm text-gray-900"><%= format_time(@stats["avg_time_ms"]) %></span>
      </div>

      <!-- Average Inferences -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Avg Inferences:</span>
        <span class="text-sm text-gray-900"><%= format_number(@stats["avg_inferences"]) %></span>
      </div>

      <!-- Error Display -->
      <%= if @stats["error"] do %>
        <div class="mt-3 p-3 bg-red-50 border border-red-200 rounded-md">
          <p class="text-sm text-red-800">
            <strong>Error:</strong> <%= @stats["error"] %>
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  def render_overall_stats(stats) do
    assigns = %{stats: stats}

    ~H"""
    <div class="space-y-3">
      <!-- Debug Status -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Debug Mode:</span>
        <span class={[
          "px-2 py-1 text-xs font-medium rounded-full",
          if(@stats["debug_enabled"], do: "bg-blue-100 text-blue-800", else: "bg-gray-100 text-gray-800")
        ]}>
          <%= if @stats["debug_enabled"], do: "Enabled", else: "Disabled" %>
        </span>
      </div>

      <!-- Rate Limit -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Rate Limit:</span>
        <span class="text-sm text-gray-900"><%= format_time(@stats["rate_limit_ms"]) %></span>
      </div>

      <!-- Total Queries -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Total Queries:</span>
        <span class="text-sm text-gray-900"><%= format_number(@stats["query_count"]) %></span>
      </div>

      <!-- Total Inferences -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Total Inferences:</span>
        <span class="text-sm text-gray-900"><%= format_number(@stats["total_inferences"]) %></span>
      </div>

      <!-- Total Time -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Total Time:</span>
        <span class="text-sm text-gray-900"><%= format_time(@stats["total_time_ms"]) %></span>
      </div>

      <!-- Average Time -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Avg Time:</span>
        <span class="text-sm text-gray-900"><%= format_time(@stats["avg_time_ms"]) %></span>
      </div>

      <!-- Average Inferences -->
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-700">Avg Inferences:</span>
        <span class="text-sm text-gray-900"><%= format_number(@stats["avg_inferences"]) %></span>
      </div>
    </div>
    """
  end
end
