defmodule Resdayn.Importer.Record.AppliedMagicEffect do
  @moduledoc """
  Imports AppliedMagicEffect records by collecting effects from spells, potions, and enchantments.

  Each effect is stored with a polymorphic parent reference (parent_type, parent_id) and an index
  to preserve ordering.
  """

  use Resdayn.Importer.Record

  alias Resdayn.Importer.Helpers

  def process(records, _opts) do
    template_lookup = Helpers.build_magic_effect_template_lookup(records)

    spell_effects = collect_spell_effects(records, template_lookup)
    potion_effects = collect_potion_effects(records, template_lookup)
    enchantment_effects = collect_enchantment_effects(records, template_lookup)

    all_effects = spell_effects ++ potion_effects ++ enchantment_effects

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Mechanics.AppliedMagicEffect,
      records: all_effects,
      conflict_keys: [:parent_type, :parent_id, :index]
    }
  end

  defp collect_spell_effects(records, template_lookup) do
    records
    |> of_type(Resdayn.Parser.Record.Spell)
    |> Enum.flat_map(fn record ->
      record.data
      |> Map.get(:enchantments, [])
      |> transform_effects(record.data.id, :spell, template_lookup)
    end)
  end

  defp collect_potion_effects(records, template_lookup) do
    records
    |> of_type(Resdayn.Parser.Record.Potion)
    |> Enum.flat_map(fn record ->
      record.data
      |> Map.get(:effects, [])
      |> transform_effects(record.data.id, :potion, template_lookup)
    end)
  end

  defp collect_enchantment_effects(records, template_lookup) do
    records
    |> of_type(Resdayn.Parser.Record.Enchantment)
    |> Enum.flat_map(fn record ->
      record.data
      |> Map.get(:enchantments, [])
      |> transform_effects(record.data.id, :enchantment, template_lookup)
    end)
  end

  defp transform_effects(effects, parent_id, parent_type, template_lookup) do
    effects
    |> Enum.with_index()
    |> Enum.map(fn {effect, index} ->
      applied = effect.applied_magic_effect

      {skill_id, attribute_id} =
        Helpers.filter_magic_effect_values(
          applied.magic_effect_id,
          applied.skill_id,
          applied.attribute_id,
          template_lookup
        )

      %{
        parent_type: parent_type,
        parent_id: parent_id,
        index: index,
        magic_effect_id:
          Helpers.build_magic_effect_id(applied.magic_effect_id, skill_id, attribute_id),
        duration: effect.duration,
        magnitude: effect.magnitude,
        range: effect.range,
        area: effect.area
      }
    end)
  end
end
