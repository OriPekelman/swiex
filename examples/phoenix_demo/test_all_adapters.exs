#!/usr/bin/env elixir

# Simple test for all adapters without loading Phoenix or CauseNet data
IO.puts("🧠 Testing All Three Prolog Adapters")
IO.puts("=" |> String.duplicate(40))

# Test adapter listing
IO.puts("\n📋 Available Adapters:")
try do
  adapters = Swiex.Prolog.list_adapters()
  
  for %{adapter: adapter, info: info, health: health} <- adapters do
    status = if health == :ok, do: "✅", else: "❌"
    IO.puts("  #{status} #{info.name} (#{info.type}) - #{adapter}")
  end
rescue
  error ->
    IO.puts("  ❌ Error listing adapters: #{inspect(error)}")
end

# Test query_all functionality
IO.puts("\n🧪 Testing query_all with 'true' query:")
try do
  results = Swiex.Prolog.query_all("true")
  
  for {adapter, result} <- results do
    adapter_name = case adapter do
      Swiex.Adapters.SwiAdapter -> "SWI-Prolog"
      Swiex.Adapters.ErlogAdapter -> "Erlog"  
      Swiex.Adapters.ScryerAdapter -> "Scryer Prolog"
      _ -> "#{adapter}"
    end
    
    case result do
      {:ok, _} -> IO.puts("  ✅ #{adapter_name}: Success")
      {:error, {:adapter_not_available, _}} -> IO.puts("  ❌ #{adapter_name}: Not Available") 
      {:error, reason} -> IO.puts("  ❌ #{adapter_name}: Error - #{inspect(reason)}")
    end
  end
rescue
  error ->
    IO.puts("  ❌ Error running query_all: #{inspect(error)}")
end

IO.puts("\n✅ All adapter test completed!")