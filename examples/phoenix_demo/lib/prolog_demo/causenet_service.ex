defmodule PrologDemo.CauseNetService do
  @moduledoc """
  Service module for fetching and processing CauseNet data.
  CauseNet is a large-scale causal knowledge graph with over 199K causal relationships.
  """

  alias PrologDemo.CauseNetDataLoader

  @doc """
  Fetch causal relationships from CauseNet API for a given concept.
  """
  def fetch_causal_relationships(concept, limit \\ 100) do
    # For real Prolog demo, use actual CauseNet data only
    # No fallbacks - demonstrate true Prolog capabilities
    {:ok, CauseNetDataLoader.load_causenet_data() |> Enum.take(limit)}
  end

  @doc """
  Fetch all available concepts from CauseNet.
  """
  def fetch_available_concepts(limit \\ 1000) do
    # Extract unique concepts from real CauseNet data
    relationships = CauseNetDataLoader.load_causenet_data()
    
    causes = relationships |> Enum.map(fn {cause, _} -> cause end)
    effects = relationships |> Enum.map(fn {_, effect} -> effect end)
    
    unique_concepts = (causes ++ effects) |> Enum.uniq() |> Enum.take(limit)
    {:ok, unique_concepts}
  end

  @doc """
  Convert CauseNet relationships to Prolog facts.
  """
  def relationships_to_prolog_facts(relationships) do
    relationships
    |> Enum.map(fn relationship ->
      # Convert relationship to Prolog fact format
      "causes('#{escape_prolog_string(relationship.cause)}', '#{escape_prolog_string(relationship.effect)}')"
    end)
  end

  @doc """
  Get comprehensive sample data for demonstration purposes.
  This includes real-world causal relationships from various domains.
  """
  def get_real_causenet_data do
    # Load full CauseNet dataset for real Prolog demo
    CauseNetDataLoader.load_causenet_data()
  end

  def get_death_related_data do
    CauseNetDataLoader.load_death_related_data()
  end

  def get_causenet_prolog_facts do
    # Load full CauseNet dataset - no limits for real Prolog capabilities demo
    CauseNetDataLoader.load_causenet_data()
    |> CauseNetDataLoader.to_prolog_facts()
  end

  def get_death_related_prolog_facts do
    get_death_related_data()
    |> CauseNetDataLoader.to_prolog_facts()
  end

  def get_sample_causenet_data do
    [
      # Health and Medicine
      %{cause: "smoking", effect: "lung_cancer", confidence: 0.95, domain: "health"},
      %{cause: "smoking", effect: "heart_disease", confidence: 0.88, domain: "health"},
      %{cause: "smoking", effect: "emphysema", confidence: 0.92, domain: "health"},
      %{cause: "obesity", effect: "diabetes", confidence: 0.89, domain: "health"},
      %{cause: "obesity", effect: "hypertension", confidence: 0.85, domain: "health"},
      %{cause: "obesity", effect: "sleep_apnea", confidence: 0.78, domain: "health"},
      %{cause: "alcohol_consumption", effect: "liver_disease", confidence: 0.91, domain: "health"},
      %{cause: "alcohol_consumption", effect: "alcoholism", confidence: 0.87, domain: "health"},
      %{cause: "stress", effect: "anxiety", confidence: 0.82, domain: "health"},
      %{cause: "stress", effect: "depression", confidence: 0.79, domain: "health"},
      %{cause: "stress", effect: "insomnia", confidence: 0.76, domain: "health"},
      %{cause: "poor_diet", effect: "obesity", confidence: 0.84, domain: "health"},
      %{cause: "poor_diet", effect: "heart_disease", confidence: 0.81, domain: "health"},
      %{cause: "lack_of_exercise", effect: "obesity", confidence: 0.86, domain: "health"},
      %{cause: "lack_of_exercise", effect: "heart_disease", confidence: 0.83, domain: "health"},
      %{cause: "genetic_factors", effect: "cancer", confidence: 0.75, domain: "health"},
      %{cause: "genetic_factors", effect: "diabetes", confidence: 0.72, domain: "health"},
      %{cause: "age", effect: "cancer", confidence: 0.68, domain: "health"},
      %{cause: "age", effect: "heart_disease", confidence: 0.71, domain: "health"},
      %{cause: "age", effect: "osteoporosis", confidence: 0.73, domain: "health"},

      # Environmental and Climate
      %{cause: "greenhouse_gas_emissions", effect: "global_warming", confidence: 0.97, domain: "environment"},
      %{cause: "global_warming", effect: "climate_change", confidence: 0.96, domain: "environment"},
      %{cause: "climate_change", effect: "extreme_weather", confidence: 0.94, domain: "environment"},
      %{cause: "climate_change", effect: "sea_level_rise", confidence: 0.93, domain: "environment"},
      %{cause: "climate_change", effect: "ocean_acidification", confidence: 0.89, domain: "environment"},
      %{cause: "deforestation", effect: "carbon_dioxide_increase", confidence: 0.91, domain: "environment"},
      %{cause: "deforestation", effect: "soil_erosion", confidence: 0.88, domain: "environment"},
      %{cause: "deforestation", effect: "biodiversity_loss", confidence: 0.92, domain: "environment"},
      %{cause: "fossil_fuel_combustion", effect: "air_pollution", confidence: 0.95, domain: "environment"},
      %{cause: "fossil_fuel_combustion", effect: "greenhouse_gas_emissions", confidence: 0.94, domain: "environment"},
      %{cause: "air_pollution", effect: "respiratory_diseases", confidence: 0.87, domain: "environment"},
      %{cause: "air_pollution", effect: "premature_deaths", confidence: 0.85, domain: "environment"},
      %{cause: "water_pollution", effect: "waterborne_diseases", confidence: 0.89, domain: "environment"},
      %{cause: "water_pollution", effect: "ecosystem_damage", confidence: 0.86, domain: "environment"},
      %{cause: "plastic_waste", effect: "ocean_pollution", confidence: 0.90, domain: "environment"},
      %{cause: "plastic_waste", effect: "wildlife_harm", confidence: 0.88, domain: "environment"},

      # Social and Economic
      %{cause: "poverty", effect: "crime", confidence: 0.78, domain: "social"},
      %{cause: "poverty", effect: "poor_education", confidence: 0.82, domain: "social"},
      %{cause: "poverty", effect: "poor_health", confidence: 0.85, domain: "social"},
      %{cause: "poverty", effect: "social_inequality", confidence: 0.80, domain: "social"},
      %{cause: "unemployment", effect: "poverty", confidence: 0.84, domain: "social"},
      %{cause: "unemployment", effect: "mental_health_issues", confidence: 0.76, domain: "social"},
      %{cause: "unemployment", effect: "social_unrest", confidence: 0.72, domain: "social"},
      %{cause: "income_inequality", effect: "social_tension", confidence: 0.79, domain: "social"},
      %{cause: "income_inequality", effect: "political_polarization", confidence: 0.75, domain: "social"},
      %{cause: "lack_of_education", effect: "unemployment", confidence: 0.81, domain: "social"},
      %{cause: "lack_of_education", effect: "poverty", confidence: 0.83, domain: "social"},
      %{cause: "social_media", effect: "information_overload", confidence: 0.77, domain: "social"},
      %{cause: "social_media", effect: "mental_health_issues", confidence: 0.74, domain: "social"},
      %{cause: "social_media", effect: "political_polarization", confidence: 0.73, domain: "social"},

      # Technology and Innovation
      %{cause: "artificial_intelligence", effect: "automation", confidence: 0.93, domain: "technology"},
      %{cause: "automation", effect: "job_displacement", confidence: 0.87, domain: "technology"},
      %{cause: "automation", effect: "productivity_increase", confidence: 0.91, domain: "technology"},
      %{cause: "internet", effect: "information_access", confidence: 0.95, domain: "technology"},
      %{cause: "internet", effect: "social_media", confidence: 0.89, domain: "technology"},
      %{cause: "internet", effect: "e_commerce", confidence: 0.92, domain: "technology"},
      %{cause: "smartphones", effect: "social_media_usage", confidence: 0.90, domain: "technology"},
      %{cause: "smartphones", effect: "digital_addiction", confidence: 0.78, domain: "technology"},
      %{cause: "smartphones", effect: "productivity_tools", confidence: 0.85, domain: "technology"},
      %{cause: "renewable_energy", effect: "carbon_emissions_reduction", confidence: 0.88, domain: "technology"},
      %{cause: "renewable_energy", effect: "energy_independence", confidence: 0.82, domain: "technology"},
      %{cause: "electric_vehicles", effect: "air_pollution_reduction", confidence: 0.86, domain: "technology"},
      %{cause: "electric_vehicles", effect: "fossil_fuel_dependency_reduction", confidence: 0.84, domain: "technology"},

      # Disease Progression Chains
      %{cause: "lung_cancer", effect: "metastasis", confidence: 0.85, domain: "health"},
      %{cause: "metastasis", effect: "organ_failure", confidence: 0.90, domain: "health"},
      %{cause: "organ_failure", effect: "death", confidence: 0.95, domain: "health"},
      %{cause: "diabetes", effect: "kidney_disease", confidence: 0.83, domain: "health"},
      %{cause: "kidney_disease", effect: "kidney_failure", confidence: 0.88, domain: "health"},
      %{cause: "kidney_failure", effect: "death", confidence: 0.92, domain: "health"},
      %{cause: "heart_disease", effect: "heart_attack", confidence: 0.87, domain: "health"},
      %{cause: "heart_attack", effect: "heart_failure", confidence: 0.89, domain: "health"},
      %{cause: "heart_failure", effect: "death", confidence: 0.91, domain: "health"},
      %{cause: "hypertension", effect: "stroke", confidence: 0.84, domain: "health"},
      %{cause: "stroke", effect: "brain_damage", confidence: 0.86, domain: "health"},
      %{cause: "brain_damage", effect: "disability", confidence: 0.88, domain: "health"},
      %{cause: "disability", effect: "reduced_quality_of_life", confidence: 0.85, domain: "health"},

      # Climate Impact Chains
      %{cause: "extreme_weather", effect: "natural_disasters", confidence: 0.89, domain: "environment"},
      %{cause: "natural_disasters", effect: "infrastructure_damage", confidence: 0.91, domain: "environment"},
      %{cause: "infrastructure_damage", effect: "economic_losses", confidence: 0.87, domain: "environment"},
      %{cause: "economic_losses", effect: "social_instability", confidence: 0.78, domain: "environment"},
      %{cause: "social_instability", effect: "political_unrest", confidence: 0.75, domain: "environment"},
      %{cause: "sea_level_rise", effect: "coastal_flooding", confidence: 0.92, domain: "environment"},
      %{cause: "coastal_flooding", effect: "population_displacement", confidence: 0.85, domain: "environment"},
      %{cause: "population_displacement", effect: "refugee_crisis", confidence: 0.82, domain: "environment"},
      %{cause: "refugee_crisis", effect: "social_tension", confidence: 0.79, domain: "environment"},
      %{cause: "ocean_acidification", effect: "marine_ecosystem_collapse", confidence: 0.88, domain: "environment"},
      %{cause: "marine_ecosystem_collapse", effect: "fishery_collapse", confidence: 0.90, domain: "environment"},
      %{cause: "fishery_collapse", effect: "food_security_issues", confidence: 0.83, domain: "environment"},
      %{cause: "food_security_issues", effect: "social_unrest", confidence: 0.77, domain: "environment"},

      # Technology Impact Chains
      %{cause: "job_displacement", effect: "unemployment", confidence: 0.89, domain: "technology"},
      %{cause: "unemployment", effect: "economic_inequality", confidence: 0.84, domain: "technology"},
      %{cause: "economic_inequality", effect: "social_tension", confidence: 0.81, domain: "technology"},
      %{cause: "productivity_increase", effect: "economic_growth", confidence: 0.86, domain: "technology"},
      %{cause: "economic_growth", effect: "standard_of_living_improvement", confidence: 0.82, domain: "technology"},
      %{cause: "digital_addiction", effect: "mental_health_issues", confidence: 0.76, domain: "technology"},
      %{cause: "mental_health_issues", effect: "productivity_decrease", confidence: 0.78, domain: "technology"},
      %{cause: "productivity_decrease", effect: "economic_losses", confidence: 0.80, domain: "technology"},

      # Social Impact Chains
      %{cause: "social_inequality", effect: "political_polarization", confidence: 0.83, domain: "social"},
      %{cause: "political_polarization", effect: "governance_dysfunction", confidence: 0.79, domain: "social"},
      %{cause: "governance_dysfunction", effect: "social_unrest", confidence: 0.81, domain: "social"},
      %{cause: "social_unrest", effect: "political_instability", confidence: 0.85, domain: "social"},
      %{cause: "political_instability", effect: "economic_decline", confidence: 0.82, domain: "social"},
      %{cause: "economic_decline", effect: "poverty_increase", confidence: 0.87, domain: "social"},
      %{cause: "poverty_increase", effect: "crime_increase", confidence: 0.80, domain: "social"},
      %{cause: "crime_increase", effect: "social_fear", confidence: 0.78, domain: "social"},
      %{cause: "social_fear", effect: "social_isolation", confidence: 0.75, domain: "social"},
      %{cause: "social_isolation", effect: "mental_health_issues", confidence: 0.77, domain: "social"}
    ]
  end

  @doc """
  Get common concepts that users can explore.
  """
  def get_common_concepts do
    [
      # Health concepts
      "smoking", "obesity", "diabetes", "cancer", "heart_disease", "stress", "alcohol",
      "exercise", "diet", "genetics", "age", "hypertension", "stroke",

      # Environmental concepts
      "global_warming", "climate_change", "deforestation", "pollution", "fossil_fuels",
      "renewable_energy", "biodiversity", "ocean_acidification", "sea_level_rise",

      # Social concepts
      "poverty", "education", "unemployment", "inequality", "social_media", "crime",
      "politics", "governance", "social_unrest", "refugee_crisis",

      # Technology concepts
      "artificial_intelligence", "automation", "internet", "smartphones", "social_media",
      "electric_vehicles", "renewable_energy", "digital_addiction",

      # Economic concepts
      "economic_growth", "inflation", "unemployment", "poverty", "inequality",
      "trade", "globalization", "recession", "financial_crisis"
    ]
  end

  @doc """
  Get domain-specific causal relationships.
  """
  def get_domain_relationships(domain) do
    get_sample_causenet_data()
    |> Enum.filter(&(&1.domain == domain))
  end

  @doc """
  Search for concepts that match a query.
  """
  def search_concepts(query, limit \\ 20) do
    concepts = get_common_concepts()

    concepts
    |> Enum.filter(&String.contains?(String.downcase(&1), String.downcase(query)))
    |> Enum.take(limit)
  end

  # Private functions

  defp fetch_from_api(_concept, _limit) do
    # This would make actual HTTP requests to CauseNet API
    # For now, return error to trigger fallback
    {:error, "API not implemented yet"}
  end

  defp escape_prolog_string(string) do
    string
    |> String.replace("'", "\\'")
    |> String.replace("\"", "\\\"")
  end
end
