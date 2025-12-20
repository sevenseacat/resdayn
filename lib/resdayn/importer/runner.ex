defmodule Resdayn.Importer.Runner do
  @moduledoc """
  Run a full import for a given file.

  `filename` should be the base filename for an ESM/ESP file in `priv/data`, eg. "Morrowind.esm"
  """

  require Logger
  alias Resdayn.Importer.Record
  alias Resdayn.Importer.FastBulkImport
  alias Resdayn.Codex.Changes.BulkRelationshipImport

  def run(filename) do
    Logger.configure(level: :info)

    Logger.info("Starting import for #{filename}...")

    records =
      Path.join([:code.priv_dir(:resdayn), "data", filename])
      |> parse_records()

    {time, _result} =
      :timer.tc(
        fn ->
          # Resources are listed in dependency order.
          # Order matters: resources must be imported after their dependencies.
          [
            Record.DataFile,
            # === Phase 1: No dependencies ===
            Record.GameSetting,
            Record.Attribute,
            Record.GlobalVariable,
            Record.Skill,
            Record.Script,
            # === Phase 2: Depends on Phase 1 ===
            Record.Sound,
            # === Phase 3: Depends on Phase 1-2 ===
            Record.MagicEffect,
            Record.Class,
            Record.ClassSkill,
            Record.Birthsign,
            Record.Spell,
            Record.Enchantment,
            Record.Race,
            Record.Faction,
            # === Phase 4: Depends on Race ===
            Record.BodyPart,
            # === Phase 5: Referencable resources (depends on Phase 1-4) ===
            Record.StaticObject,
            Record.Activator,
            Record.Light,
            Record.Door,
            Record.Book,
            Record.Weapon,
            Record.MiscellaneousItem,
            Record.Armor,
            Record.Clothing,
            Record.Ingredient,
            Record.Potion,
            Record.Tool,
            Record.AlchemyApparatus,
            Record.SoundGenerator,
            Record.Container,
            Record.ItemLevelledList,
            Record.CreatureLevelledList,
            Record.Creature,
            Record.NPC,
            # === Phase 6: Depends on CreatureLevelledList ===
            Record.Region,
            # === Phase 7: Cells and references ===
            Record.Cell,
            Record.CellReference,
            # === Phase 8: Relationship importers ===
            Record.RaceSkillBonus,
            Record.FactionReaction,
            Record.InventoryItem,
            Record.ContainerItem,
            Record.CreatureInventoryItem,
            # === Phase 9: Dialogue ===
            Record.DialogueTopic,
            Record.DialogueResponse,
            Record.Quest,
            Record.JournalEntry
          ]
          |> Enum.each(fn record_type ->
            import_record_type(record_type, records, filename: filename)
          end)
        end,
        :millisecond
      )

    Logger.info("Completed import in #{Float.round(time / 1000, 2)} seconds.")
  end

  defp parse_records(filename) do
    {time, result} =
      :timer.tc(fn -> Resdayn.Parser.read(filename) |> Enum.to_list() end, :millisecond)

    Logger.debug("Parsed #{length(result)} records in #{Float.round(time / 1000, 2)} seconds.")

    result
  end

  defp import_record_type(record_type, records, opts) do
    name = String.split(Atom.to_string(record_type), ".") |> List.last()

    {time, result} =
      :timer.tc(
        fn ->
          case apply(record_type, :process, [records, opts]) do
            %{type: :bulk_relationship} = config ->
              import_bulk_relationships(config, opts)

            %{type: :fast_bulk} = config ->
              import_fast_bulk(config, opts)
          end
        end,
        :millisecond
      )

    log_import_result(name, result, time)
  end

  defp import_bulk_relationships(config, opts) do
    source_file_id = Keyword.get(opts, :filename)

    {:ok, stats} =
      BulkRelationshipImport.import(
        config.records,
        parent_resource: config.parent_resource,
        related_resource: config.related_resource,
        parent_key: config.parent_key,
        id_field: config.id_field,
        relationship_key: config.relationship_key,
        deleted_key: config[:deleted_key],
        on_missing: config.on_missing,
        source_file_id: source_file_id
      )

    {:bulk_relationship, stats}
  end

  defp import_fast_bulk(config, opts) do
    source_file_id = Keyword.get(opts, :filename)

    {:ok, stats} =
      FastBulkImport.import(
        config.records,
        config.resource,
        source_file_id: source_file_id,
        conflict_keys: config[:conflict_keys] || [:id]
      )

    {:fast_bulk, stats}
  end

  defp log_import_result(name, result, time) do
    time_str = Float.round(time / 1000, 2)

    case result do
      {:bulk_relationship, stats} ->
        messages =
          [
            if(stats.created > 0, do: "#{stats.created} relationships created"),
            if(stats.updated > 0, do: "#{stats.updated} relationships updated"),
            if(stats.deleted > 0, do: "#{stats.deleted} relationships deleted")
          ]
          |> Enum.reject(&is_nil/1)

        if not Enum.empty?(messages) do
          Logger.debug("#{name}: #{Enum.join(messages, ", ")} in #{time_str} seconds.")
        end

      {:fast_bulk, stats} ->
        if stats.total > 0 do
          Logger.debug("#{name}: #{stats.total} records upserted in #{time_str} seconds.")
        end
    end
  end
end
