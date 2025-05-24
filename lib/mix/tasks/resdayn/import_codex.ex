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

  # To be imported
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
  # Record.NPC,
  # Record.Armour,
  # Record.Clothing,
  # Record.RepairItem,
  # Record.Activator,
  # Record.AlchemyApparatus,
  # Record.Lockpick,
  # Record.Probe,
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
      Record.Sound,
      Record.Script,
      Record.MagicEffect,
      Record.Spell,
      Record.Race,
      Record.Enchantment,
      Record.Ingredient,
      Record.Faction,
      Record.MiscellaneousItem,
      Record.Tool,
      Record.AlchemyApparatus,
      Record.Potion
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
    %{resource: resource, data: data} = apply(importer, :process, [records, opts])
    length = length(data)

    if length > 0 do
      Ash.bulk_create!(data, resource, :import, return_errors?: true, stop_on_error?: true)
      Owl.IO.puts("#{name}: #{length} records inserted.")
    end
  end
end
