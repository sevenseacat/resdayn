defmodule Resdayn.Importer.Record.Enchantment do
  use Resdayn.Importer.Record

  alias Resdayn.Importer.Helpers

  def process(records, _opts) do
    template_lookup = Helpers.build_magic_effect_template_lookup(records)

    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Enchantment)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :type, :cost, :charge])
        |> Map.put(:autocalc, record.data.flags.autocalc)
        |> Map.put(
          :effects,
          transform_effects(Map.get(record.data, :enchantments, []), template_lookup)
        )
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Mechanics.Enchantment,
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
