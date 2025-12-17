defmodule Resdayn.Importer.Runner do
  @moduledoc """
  Run a full import for a given fil.

  `filename` should be the base filename for an ESM/ESP file in `priv/data`, eg. "Morrowind.esm"
  """

  require Logger
  alias Resdayn.Importer.Record

  def run(filename) do
    Logger.configure(level: :info)

    Logger.notice("Importing #{filename}...")

    records =
      Path.join([:code.priv_dir(:resdayn), "data", filename])
      |> parse_records()

    [
      Record.DataFile,
      Record.GameSetting,
      Record.Attribute,
      Record.GlobalVariable,
      Record.Skill,
      Record.Class,
      Record.ClassSkill,
      Record.Sound,
      Record.Script,
      Record.MagicEffect,
      Record.Spell,
      Record.Race,
      Record.RaceSkillBonus,
      Record.Enchantment,
      Record.Ingredient,
      Record.Faction,
      Record.FactionReaction,
      Record.MiscellaneousItem,
      Record.Tool,
      Record.AlchemyApparatus,
      Record.Potion,
      Record.StaticObject,
      Record.Activator,
      Record.Light,
      Record.Birthsign,
      Record.BodyPart,
      Record.Book,
      Record.Clothing,
      Record.Door,
      Record.Weapon,
      Record.Armor,
      Record.NPC,
      Record.ItemLevelledList,
      Record.ItemLevelledListItem,
      Record.InventoryItem,
      Record.Container,
      Record.ContainerItem,
      Record.SoundGenerator,
      Record.Creature,
      Record.CreatureInventoryItem,
      Record.CreatureLevelledList,
      Record.Region,
      Record.Cell,
      Record.CellReference,
      Record.Quest,
      Record.JournalEntry,
      Record.DialogueTopic,
      Record.DialogueResponse
    ]
    |> Enum.each(fn record_type ->
      import_record_type(record_type, records, filename: filename)
    end)
  end

  defp parse_records(filename) do
    {time, result} =
      :timer.tc(fn -> Resdayn.Parser.read(filename) |> Enum.to_list() end, :millisecond)

    Logger.info("Parsed #{length(result)} records in #{Float.round(time / 1000, 2)} seconds.")

    result
  end

  defp import_record_type(record_type, records, opts) do
    name = String.split(Atom.to_string(record_type), ".") |> List.last()

    {time, {create_length, update_length, relationship_stats}} =
      :timer.tc(
        fn ->
          to_import = apply(record_type, :process, [records, opts])

          create = Map.get(to_import, :create, [])
          create_length = length(create)

          if create_length > 0 do
            Ash.bulk_create!(create, to_import.resource, :import_create,
              return_errors?: true,
              stop_on_error?: true
            )
          end

          update = Map.get(to_import, :update, [])
          update_length = length(update)

          # Track relationship counts from OptimizedRelationshipImport
          total_relationship_stats = %{created: 0, updated: 0, deleted: 0}

          relationship_stats =
            update
            |> Task.async_stream(fn changeset ->
              {Ash.update(changeset), changeset.context[:import_stats]}
            end)
            |> Enum.reduce(total_relationship_stats, fn {:ok, {changeset, import_stats}}, acc ->
              case changeset do
                {:ok, _result} ->
                  # Check if this update used OptimizedRelationshipImport
                  case import_stats do
                    nil ->
                      acc

                    stats ->
                      %{
                        created: acc.created + stats.created,
                        updated: acc.updated + stats.updated,
                        deleted: acc.deleted + stats.deleted
                      }
                  end

                {:error, error} ->
                  dbg(changeset)
                  dbg(error)
                  exit(1)
              end
            end)

          {create_length, update_length, relationship_stats}
        end,
        :millisecond
      )

    # Report counts appropriately
    if relationship_stats.created > 0 || relationship_stats.updated > 0 ||
         relationship_stats.deleted > 0 do
      # This record type uses OptimizedRelationshipImport - report relationship counts
      created_msg =
        if relationship_stats.created > 0,
          do: "#{relationship_stats.created} relationships created",
          else: nil

      updated_msg =
        if relationship_stats.updated > 0,
          do: "#{relationship_stats.updated} relationships updated",
          else: nil

      deleted_msg =
        if relationship_stats.deleted > 0,
          do: "#{relationship_stats.deleted} relationships deleted",
          else: nil

      messages = [created_msg, updated_msg, deleted_msg] |> Enum.reject(&is_nil/1)

      if not Enum.empty?(messages) do
        Logger.info(
          "#{name}: #{Enum.join(messages, ", ")} in #{Float.round(time / 1000, 2)} seconds."
        )
      end
    else
      # This record type uses individual record processing - report record counts
      if create_length > 0 || update_length > 0 do
        Logger.info(
          "#{name}: #{create_length} records inserted, #{update_length} records updated in #{Float.round(time / 1000, 2)} seconds."
        )
      end
    end
  end
end
