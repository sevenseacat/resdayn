defmodule Mix.Tasks.Resdayn.ImportCodex do
  use Mix.Task

  alias Resdayn.Importer.Record

  # All of the files we care about parsing.
  @all_files [
    "Morrowind.esm",
    "Tribunal.esm",
    "Bloodmoon.esm",
    "master_index.esp",
    "Tamriel_Data.esm",
    "TR_Mainland.esm",
    "TR_Factions.esp",
    "Sky_Main.esm",
    "Cyr_Main.esm"
  ]

  @requirements ["app.start"]

  def run([filename]) do
    Logger.configure(level: :info)

    filename
    |> load_records()
    |> run_importer(filename)
  end

  def run([filename, resource]) do
    Logger.configure(level: :info)
    records = load_records(filename)
    import_records(:"Elixir.Resdayn.Importer.Record.#{resource}", records, filename: filename)
  end

  def run(_argv) do
    Logger.configure(level: :info)

    Owl.IO.puts("* File parsing")

    Task.async_stream(
      @all_files,
      fn filename -> {filename, load_records(filename)} end,
      ordered: true,
      timeout: 30_000
    )
    |> Enum.to_list()
    |> Enum.map(fn {:ok, {filename, records}} ->
      run_importer(records, filename)
    end)
  end

  def run_importer(records, filename) do
    Owl.IO.puts("\n* #{filename}")

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
    |> Enum.each(fn importer ->
      import_records(importer, records, filename: filename)
    end)
  end

  defp load_records(filename) do
    Owl.Spinner.start(id: filename)
    Owl.Spinner.update_label(id: filename, label: "#{filename}: Parsing...")

    {time, result} =
      :timer.tc(
        fn -> Resdayn.Parser.read(Path.join(["../data/", filename])) |> Enum.to_list() end,
        :millisecond
      )

    Owl.Spinner.stop(
      id: filename,
      resolution: :ok,
      label: "#{filename}: #{length(result)} records parsed in #{Float.round(time / 1000, 2)}s."
    )

    result
  end

  defp import_records(importer, records, opts) do
    name = String.split(Atom.to_string(importer), ".") |> List.last()
    filename = Keyword.fetch!(opts, :filename)

    # Special handling for DataFile importer - it doesn't use source tracking
    if importer == Record.DataFile do
      import_records_without_tracking(importer, records, opts, name)
    else
      import_records_with_tracking(importer, records, opts, name, filename)
    end
  end

  defp import_records_without_tracking(importer, records, opts, name) do
    to_perform = apply(importer, :process, [records, opts])

    create = Map.get(to_perform, :create, [])
    create_length = length(create)

    Ash.bulk_create!(create, to_perform.resource, :import_create,
      return_errors?: true,
      stop_on_error?: true
    )

    update = Map.get(to_perform, :update, [])
    update_length = length(update)

    Enum.each(update, fn changeset ->
      case Ash.update(changeset) do
        {:ok, _} ->
          :ok

        {:error, error} ->
          dbg(changeset)
          dbg(error)
          exit(1)
      end
    end)

    if create_length > 0 || update_length > 0 do
      Owl.IO.puts("#{name}: #{create_length} records inserted, #{update_length} records updated")
    end
  end

  defp import_records_with_tracking(importer, records, opts, name, filename) do
    # Add source file ID to opts for the importer to use
    opts_with_source = Keyword.put(opts, :source_file_id, filename)

    # Process records with source tracking support
    to_performed = apply(importer, :process, [records, opts_with_source])

    create = Map.get(to_performed, :create, [])
    create_length = length(create)

    if create_length > 0 do
      Ash.bulk_create!(create, to_performed.resource, :import_create,
        return_errors?: true,
        stop_on_error?: true
      )
    end

    update = Map.get(to_performed, :update, [])
    update_length = length(update)

    Enum.each(update, fn changeset ->
      case Ash.update(changeset) do
        {:ok, _} ->
          :ok

        {:error, error} ->
          dbg(changeset)
          dbg(error)
          exit(1)
      end
    end)

    if create_length > 0 || update_length > 0 do
      Owl.IO.puts("#{name}: #{create_length} records inserted, #{update_length} records updated")
    end
  end
end
