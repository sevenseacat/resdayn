defmodule Resdayn.Importer.Record.Spell do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Spell)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:id, :name, :type, :cost])
      |> Map.put(:effects, transform_effects(record.data.enchantments))
      |> with_flags(:flags, record.flags)
      |> with_flags(:spell_flags, record.data.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Mechanics.Spell, opts)
  end

  defp transform_effects(enchantments) do
    Enum.map(enchantments, fn effect ->
      %{
        magic_effect_id: effect.magic_effect_id,
        skill_id: effect.skill_id,
        attribute_id: effect.attribute_id,
        range: effect.range,
        area: effect.area,
        duration: effect.duration,
        magnitude: effect.magnitude
      }
    end)
  end
end
