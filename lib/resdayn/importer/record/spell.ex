defmodule Resdayn.Importer.Record.Spell do
  use Resdayn.Importer.Record

  alias Resdayn.Importer.Helpers

  def process(records, _opts) do
    template_lookup = Helpers.build_magic_effect_template_lookup(records)

    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Spell)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :name, :type, :cost])
        |> Map.put(
          :effects,
          transform_effects(Map.get(record.data, :enchantments, []), template_lookup)
        )
        |> with_flags(:flags, record.flags)
        |> with_flags(:spell_flags, record.data.flags)
      end)
      |> Enum.uniq_by(fn spell_data -> spell_data.id end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Mechanics.Spell,
      records: processed_records,
      conflict_keys: [:id]
    }
  end

  defp transform_effects(effects, template_lookup) do
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
        id: index,
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
