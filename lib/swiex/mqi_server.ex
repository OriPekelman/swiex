defmodule Swiex.MQIServer do
  @moduledoc """
  Manages the SWI-Prolog MQI server process.
  """

  use GenServer
  require Logger

  defstruct [:port, :os_pid]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Wait a bit for the system to be ready
    Process.sleep(1000)

    case start_mqi_server() do
      {:ok, port, os_pid} ->
        Logger.info("MQI server started with OS PID: #{os_pid}")
        {:ok, %__MODULE__{port: port, os_pid: os_pid}}
      {:error, reason} ->
        Logger.error("Failed to start MQI server: #{inspect(reason)}")
        {:ok, %__MODULE__{port: nil, os_pid: nil}}
    end
  end

  @impl true
  def terminate(_reason, state) do
    if state.os_pid do
      Logger.info("Stopping MQI server (PID: #{state.os_pid})")
      System.cmd("kill", ["#{state.os_pid}"])
    end
  end

  defp start_mqi_server do
    script_path = Path.join([File.cwd!(), "start_mqi_server.pl"])

    case Port.open({:spawn, "swipl -s #{script_path}"},
         [:binary, :exit_status, {:line, 1024}]) do
      port when is_port(port) ->
        # Give the server time to start
        Process.sleep(3000)
        {:ok, port, nil}  # We don't track the OS PID for now
      _ ->
        {:error, "Failed to spawn MQI server"}
    end
  rescue
    e ->
      Logger.error("Exception starting MQI server: #{inspect(e)}")
      {:error, e}
  end
end
