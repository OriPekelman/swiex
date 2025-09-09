defmodule PrologDemo.CauseNetDataLoader do
  @moduledoc """
  Loads real CauseNet precision dataset from JSONL file and converts to Prolog facts.
  """

  @data_file Path.join([__DIR__, "..", "..", "example_data", "causenet-precision.jsonl"])

  def load_causenet_data do
    case File.read(@data_file) do
      {:ok, content} ->
        IO.puts("📊 Loading full CauseNet dataset for real Prolog demo...")
        content
        |> String.split("\n")
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&Jason.decode!/1)
        |> Enum.map(&extract_causal_relation/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq_by(fn {cause, effect} -> {cause, effect} end)

      {:error, reason} ->
        raise "CauseNet data file not found: #{reason}. Real Prolog demo requires actual data file at #{@data_file}"
    end
  end

  def load_death_related_data do
    case File.read(@data_file) do
      {:ok, content} ->
        content
        |> String.split("\n")
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&Jason.decode!/1)
        |> Enum.map(&extract_causal_relation/1)
        |> Enum.reject(&is_nil/1)
        |> filter_death_related()
        |> Enum.uniq_by(fn {cause, effect} -> {cause, effect} end)
        |> Enum.take(500)  # Limit to 500 relationships for performance

      {:error, reason} ->
        raise "CauseNet data file not found: #{reason}. Real Prolog demo requires actual data file at #{@data_file}"
    end
  end

  def load_manageable_subset(limit \\ 100) do
    case File.read(@data_file) do
      {:ok, content} ->
        lines = content
        |> String.split("\n")
        |> Enum.reject(&(&1 == ""))

        # Sample from different parts of the dataset for better diversity
        total_lines = length(lines)
        sample_size = min(limit * 3, total_lines)  # Take more lines to account for filtering

        # Take samples from beginning, middle, and end of the dataset
        sampled_lines = cond do
          sample_size >= total_lines ->
            lines
          sample_size >= total_lines * 2 ->
            # Take from beginning and end
            beginning = Enum.take(lines, div(sample_size, 2))
            ending = Enum.take(lines, -div(sample_size, 2))
            beginning ++ ending
          true ->
            # Take from beginning, middle, and end
            third = div(sample_size, 3)
            beginning = Enum.take(lines, third)
            middle_start = div(total_lines, 2) - div(third, 2)
            middle = Enum.slice(lines, middle_start, third)
            ending = Enum.take(lines, -third)
            beginning ++ middle ++ ending
        end

        sampled_lines
        |> Enum.map(&Jason.decode!/1)
        |> Enum.map(&extract_causal_relation/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq_by(fn {cause, effect} -> {cause, effect} end)
        |> Enum.take(limit)

      {:error, reason} ->
        raise "CauseNet data file not found: #{reason}. Real Prolog demo requires actual data file at #{@data_file}"
    end
  end

  defp extract_causal_relation(%{"causal_relation" => %{"cause" => %{"concept" => cause}, "effect" => %{"concept" => effect}}}) do
    {normalize_concept(cause), normalize_concept(effect)}
  end

  defp extract_causal_relation(_), do: nil

  defp normalize_concept(concept) do
    concept
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/, "_")
    |> String.replace(~r/_+/, "_")
    |> String.trim("_")
  end

  defp filter_death_related(relationships) do
    death_keywords = ["death", "die", "dying", "dead", "mortality", "fatal", "lethal", "suicide", "murder", "kill"]

    relationships
    |> Enum.filter(fn {cause, effect} ->
      effect in death_keywords or
      cause in death_keywords or
      String.contains?(effect, "death") or
      String.contains?(cause, "death")
    end)
  end


  def to_prolog_facts(relationships) do
    relationships
    |> Enum.map(fn {cause, effect} ->
      "causes('#{cause}', '#{effect}')."
    end)
    |> Enum.join("\n")
  end

  def get_sample_relationships(limit \\ 50) do
    load_causenet_data()
    |> Enum.take(limit)
  end

  def get_concept_stats do
    relationships = load_causenet_data()

    causes = relationships |> Enum.map(fn {cause, _} -> cause end) |> Enum.frequencies()
    effects = relationships |> Enum.map(fn {_, effect} -> effect end) |> Enum.frequencies()

    all_concepts = Map.keys(causes) |> MapSet.new() |> MapSet.union(MapSet.new(Map.keys(effects)))

    %{
      total_relationships: length(relationships),
      total_concepts: MapSet.size(all_concepts),
      top_causes: causes |> Enum.sort_by(fn {_, count} -> count end, :desc) |> Enum.take(20),
      top_effects: effects |> Enum.sort_by(fn {_, count} -> count end, :desc) |> Enum.take(20),
      all_concepts: MapSet.to_list(all_concepts) |> Enum.sort()
    }
  end

  def get_dataset_info do
    case File.read(@data_file) do
      {:ok, content} ->
        lines = content |> String.split("\n") |> Enum.reject(&(&1 == ""))
        %{
          file_path: @data_file,
          total_lines: length(lines),
          file_size_mb: byte_size(content) / 1_000_000,
          status: "available"
        }
      {:error, reason} ->
        %{
          file_path: @data_file,
          total_lines: 0,
          file_size_mb: 0,
          status: "error: #{reason}"
        }
    end
  end
end
