defmodule Neko.Rule.Calculations do
  @moduledoc """
  calc_* functions fill rule fields with calculated values
  """

  alias Neko.Anime.Calculations, as: AnimeCalculations

  @typep rule_t :: Neko.Rule.t()
  @typep rules_t :: MapSet.t(rule_t)
  @typep anime_t :: Neko.Anime.t()
  @typep animes_t :: MapSet.t(anime_t)

  @spec calc_animes(rules_t, animes_t) :: rules_t
  def calc_animes(rules, animes) do
    rules
    |> Enum.map(&%{&1 | animes: rule_animes(&1, animes)})
    |> MapSet.new()
  end

  @spec calc_thresholds(rules_t, (rule_t -> number)) :: rules_t
  def calc_thresholds(rules, threshold) do
    rules
    |> Enum.map(&%{&1 | threshold: threshold.(&1)})
    |> calc_next_thresholds()
    |> MapSet.new()
  end

  @spec calc_durations(rules_t, animes_t) :: rules_t
  def calc_durations(rules, animes) do
    rules
    |> Enum.map(fn rule ->
      duration = AnimeCalculations.common_duration(rule.animes, animes)
      %{rule | duration: duration}
    end)
    |> MapSet.new()
  end

  @spec rule_animes(rule_t, animes_t) :: MapSet.t(anime_t)
  defp rule_animes(rule, animes) do
    animes
    |> Neko.Rule.Filters.filter_animes(rule)
    |> MapSet.new()
  end

  # access to all rules is required to calculate
  # next threshold so iterate over rules here
  @spec calc_next_thresholds(rules_t) :: rules_t
  defp calc_next_thresholds(rules) do
    rules
    |> Enum.map(&%{&1 | next_threshold: next_threshold(rules, &1)})
  end

  @spec next_threshold(rules_t, rule_t) :: number
  defp next_threshold(rules, rule) do
    rules
    |> Enum.filter(fn x ->
      x.neko_id == rule.neko_id and x.level == rule.level + 1
    end)
    |> Enum.map(& &1.threshold)
    |> List.first()
  end
end
