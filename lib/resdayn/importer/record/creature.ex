defmodule Resdayn.Importer.Record.Creature do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Creature)
    |> Enum.map(fn record ->
      spell_links =
        (record.data[:spell_ids] || [])
        |> Enum.map(&%{spell_id: &1})

      attributes =
        Enum.map(record.data[:attributes] || [], fn {key, value} ->
          %{attribute_id: key, value: value}
        end)

      record.data
      |> Map.take([
        :id,
        :name,
        :nif_model_filename,
        :script_id,
        :sound_generator_key,
        :type,
        :level,
        :health,
        :magicka,
        :fatigue,
        :soul_size,
        :combat,
        :magic,
        :stealth,
        :gold,
        :attacks,
        :scale,
        :transport_options,
        :ai_packages
      ])
      |> Map.put(:attributes, attributes)
      |> Map.put(:alert, get_in(record.data, [:ai_data, :alert]) || %{})
      |> Map.put(:spell_links, spell_links)
      |> with_flags(
        :items_vendored,
        get_in(record.data, [:ai_data, :items_vendored]) || %{}
      )
      |> with_flags(
        :services_offered,
        get_in(record.data, [:ai_data, :services_offered]) || %{}
      )
      |> with_flags(:creature_flags, record.data.flags)
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.World.Creature, opts)
  end
end
