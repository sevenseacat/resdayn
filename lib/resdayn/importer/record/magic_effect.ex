defmodule Resdayn.Importer.Record.MagicEffect do
  @moduledoc """
  Imports MagicEffect records by collecting unique (template_id, skill_id, attribute_id)
  combinations from all sources that contain effects: ingredients, potions, spells, and enchantments.

  Filters out invalid skill_id/attribute_id values based on whether the effect template
  actually uses skills or attributes (determined by game_setting_id suffix).
  """

  use Resdayn.Importer.Record

  alias Resdayn.Importer.Helpers

  def process(records, _opts) do
    template_lookup = Helpers.build_magic_effect_template_lookup(records)

    # Collect effects from all sources
    effects =
      []
      |> collect_ingredient_effects(records)
      |> collect_potion_effects(records)
      |> collect_spell_effects(records)
      |> collect_enchantment_effects(records)

    # Deduplicate by the combination of template_id, skill_id, attribute_id
    # after filtering invalid skill/attribute values
    unique_effects =
      effects
      |> Enum.map(&filter_and_build(&1, template_lookup))
      |> Enum.uniq_by(fn effect ->
        {effect.template_id, effect.skill_id, effect.attribute_id}
      end)
      |> Enum.map(fn effect ->
        %{
          id:
            Helpers.build_magic_effect_id(
              effect.template_id,
              effect.skill_id,
              effect.attribute_id
            ),
          template_id: effect.template_id,
          skill_id: effect.skill_id,
          attribute_id: effect.attribute_id
        }
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Mechanics.MagicEffect,
      records: unique_effects,
      conflict_keys: [:id]
    }
  end

  defp filter_and_build(effect, template_lookup) do
    {skill_id, attribute_id} =
      Helpers.filter_magic_effect_values(
        effect.template_id,
        effect.skill_id,
        effect.attribute_id,
        template_lookup
      )

    %{
      template_id: effect.template_id,
      skill_id: skill_id,
      attribute_id: attribute_id
    }
  end

  # Ingredients have effects at the top level (no nesting)
  defp collect_ingredient_effects(acc, records) do
    records
    |> of_type(Resdayn.Parser.Record.Ingredient)
    |> Enum.flat_map(fn record ->
      Map.get(record.data, :effects, [])
      |> Enum.map(fn effect ->
        %{
          template_id: effect.magic_effect_id,
          skill_id: effect.skill_id,
          attribute_id: effect.attribute_id
        }
      end)
    end)
    |> Kernel.++(acc)
  end

  # Potions have effects with nested applied_magic_effect
  defp collect_potion_effects(acc, records) do
    records
    |> of_type(Resdayn.Parser.Record.Potion)
    |> Enum.flat_map(fn record ->
      Map.get(record.data, :effects, [])
      |> Enum.map(&extract_from_applied_magic_effect/1)
    end)
    |> Kernel.++(acc)
  end

  # Spells have enchantments with nested applied_magic_effect
  defp collect_spell_effects(acc, records) do
    records
    |> of_type(Resdayn.Parser.Record.Spell)
    |> Enum.flat_map(fn record ->
      Map.get(record.data, :enchantments, [])
      |> Enum.map(&extract_from_applied_magic_effect/1)
    end)
    |> Kernel.++(acc)
  end

  # Enchantments have enchantments with nested applied_magic_effect
  defp collect_enchantment_effects(acc, records) do
    records
    |> of_type(Resdayn.Parser.Record.Enchantment)
    |> Enum.flat_map(fn record ->
      Map.get(record.data, :enchantments, [])
      |> Enum.map(&extract_from_applied_magic_effect/1)
    end)
    |> Kernel.++(acc)
  end

  defp extract_from_applied_magic_effect(effect) do
    applied = effect.applied_magic_effect

    %{
      template_id: applied.magic_effect_id,
      skill_id: applied.skill_id,
      attribute_id: applied.attribute_id
    }
  end
end
