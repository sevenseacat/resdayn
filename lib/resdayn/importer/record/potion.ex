defmodule Resdayn.Importer.Record.Potion do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Potion)
      |> Enum.map(fn record ->
        effects = 
          record.data.effects
          |> Enum.map(fn effect ->
            %{
              duration: effect.duration,
              magnitude: effect.magnitude,
              range: effect.range,
              area: effect.area,
              magic_effect_id: effect.magic_effect_id,
              skill_id: effect.skill_id,
              attribute_id: effect.attribute_id
            }
          end)

        record.data
        |> Map.take([:id, :name, :weight, :value, :script_id])
        |> Map.put(:nif_model_filename, record.data.nif_model)
        |> Map.put(:icon_filename, record.data.icon)
        |> Map.put(:autocalc, record.data.flags.autocalc)
        |> Map.put(:effects, effects)
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Items.Potion,
      data: data
    }
  end
end