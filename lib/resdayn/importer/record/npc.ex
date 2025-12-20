defmodule Resdayn.Importer.Record.NPC do
  use Resdayn.Importer.Record

  alias Resdayn.Importer.Helpers

  def process(records, _opts) do
    processed_records =
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

        # If transport is to exterior cells with only a global position, populate the actual cell ID
        transport_options =
          Enum.map(record.data[:transport_options] || [], fn record ->
            Map.put_new(
              record,
              :cell_id,
              Helpers.coordinates_to_cell_id(record.coordinates.position)
            )
          end)
          |> Enum.reverse()

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
          :ai_packages
        ])
        |> Map.put(:attributes, attributes)
        |> Map.put(:skills, skills)
        |> Map.put(:alert, get_in(record.data, [:ai_data, :alert]) || %{})
        |> Map.put(:spell_links, spell_links)
        |> Map.put(:transport_options, transport_options)
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

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.World.NPC,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
