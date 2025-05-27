defmodule Resdayn.Importer.Record.NPC do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    records
    |> of_type(Resdayn.Parser.Record.NPC)
    |> Enum.map(fn record ->
      spell_links =
        (record.data[:spell_ids] || [])
        |> Enum.map(&%{spell_id: &1})

      attributes =
        Enum.map(record.data[:attributes] || [], fn {key, value} ->
          %{attribute_id: key, value: value}
        end)

      skills =
        Enum.map(record.data[:skills] || [], fn {key, value} ->
          %{skill_id: key, value: value}
        end)

      record.data
      |> Map.take([
        :id,
        :name,
        :script_id,
        :level,
        :race_id,
        :class_id,
        :faction_id,
        :head_model_id,
        :hair_model_id,
        :disposition,
        :global_reputation,
        :faction_rank,
        :gold,
        :health,
        :magicka,
        :fatigue,
        :blood,
        :transport_options,
        :ai_packages
      ])
      |> Map.put(:attributes, attributes)
      |> Map.put(:skills, skills)
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
      |> with_flags(:npc_flags, record.data.flags)
      |> with_flags(:flags, record.flags)
    end)
    |> Enum.reject(&(&1.id == "player"))
    |> separate_for_import(Resdayn.Codex.World.NPC)
  end
end
