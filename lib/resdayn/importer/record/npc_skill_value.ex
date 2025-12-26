defmodule Resdayn.Importer.Record.NpcSkillValue do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.NPC)
      |> Enum.reject(&(&1.data.id == "player"))
      |> Enum.map(fn record ->
        skill_values =
          (record.data[:skills] || [])
          |> Enum.map(fn {skill_id, value} ->
            %{skill_id: skill_id, value: value}
          end)

        %{
          id: record.data.id,
          skill_values: skill_values
        }
      end)

    %{
      type: :bulk_relationship,
      parent_resource: Resdayn.Codex.World.NPC,
      related_resource: Resdayn.Codex.World.NPC.SkillValue,
      parent_key: :npc_id,
      id_field: :skill_id,
      relationship_key: :skill_values,
      on_missing: :destroy,
      records: processed_records
    }
  end
end
