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
    "TR_Factions.esp"
  ]

  # To be imported
  # Record.GlobalVariable,
  # Record.Class,
  # Record.Faction,
  # Record.Race,
  # Record.Sound,
  # Record.Skill,
  # Record.MagicEffect,
  # Record.Region,
  # Record.Birthsign,
  # Record.LandTexture,
  # Record.Static,
  # Record.Door,
  # Record.MiscellaneousItem,
  # Record.Weapon,
  # Record.Container,
  # Record.Spell,
  # Record.Creature,
  # Record.BodyPart,
  # Record.Light,
  # Record.Enchantment,
  # Record.NPC,
  # Record.Armour,
  # Record.Clothing,
  # Record.RepairItem,
  # Record.Activator,
  # Record.AlchemyApparatus,
  # Record.Lockpick,
  # Record.Probe,
  # Record.Ingredient,
  # Record.Book,
  # Record.Potion,
  # Record.LevelledItem,
  # Record.LevelledCreature,
  # Record.Cell,
  # Record.Land,
  # Record.PathGrid,
  # Record.SoundGenerator,
  # Record.DialogueTopic,
  # Record.DialogueResponse,

  def run([filename]) do
    Application.ensure_all_started(:resdayn)
    Logger.configure(level: :info)

    run_importer(filename)
  end

  def run(_argv) do
    Application.ensure_all_started(:resdayn)
    Logger.configure(level: :info)

    Enum.each(@all_files, &run_importer/1)
  end

  def run_importer(filename) do
    records = load_records(filename)

    [
      Record.DataFile,
      Record.Attribute,
      Record.GameSetting,
      Record.Script
    ]
    |> Enum.each(fn importer ->
      import_records(importer, records, filename: filename)
    end)

    IO.puts("")
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

    Owl.Spinner.start(id: importer)
    Owl.Spinner.update_label(id: importer, label: "#{name}: Processing...")

    %{resource: resource, data: data} = apply(importer, :process, [records, opts])
    length = length(data)

    Owl.Spinner.update_label(id: importer, label: "#{name}: Inserting #{length} records...")

    result =
      Ash.bulk_create!(data, resource, :import, return_errors?: true, stop_on_error?: true)

    if result.status != :success do
      label = "#{name}: #{result.error_count} errors received."
      Owl.Spinner.stop(id: importer, resolution: :error, label: label)
    else
      label = "#{name}: #{length} records inserted."
      Owl.Spinner.stop(id: importer, resolution: :ok, label: label)
    end
  end
end
