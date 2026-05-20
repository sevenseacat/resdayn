defmodule Resdayn.Importer.SearchIndex do
  @moduledoc """
  Rebuilds the search index from all searchable resources in the database.
  This should be run after all other imports are complete.
  """

  require Ash.Query

  @searchable_resources [
    {Resdayn.Codex.Items.Weapon, :weapon, :icon_filename},
    {Resdayn.Codex.Items.Armor, :armor, :icon_filename},
    {Resdayn.Codex.Items.Clothing, :clothing, :icon_filename},
    {Resdayn.Codex.Items.Book, :book, :icon_filename},
    {Resdayn.Codex.Items.Potion, :potion, :icon_filename},
    {Resdayn.Codex.Items.Ingredient, :ingredient, :icon_filename},
    {Resdayn.Codex.Items.AlchemyApparatus, :apparatus, :icon_filename},
    {Resdayn.Codex.Items.Tool, :tool, :icon_filename},
    {Resdayn.Codex.Items.MiscellaneousItem, :misc_item, :icon_filename},
    {Resdayn.Codex.World.NPC, :npc, nil},
    {Resdayn.Codex.World.Creature, :creature, nil},
    {Resdayn.Codex.World.Cell, :location, nil},
    {Resdayn.Codex.World.Region, :region, nil},
    {Resdayn.Codex.Characters.Faction, :faction, nil},
    {Resdayn.Codex.Characters.Class, :class, nil},
    {Resdayn.Codex.Characters.Race, :race, nil},
    {Resdayn.Codex.Characters.Birthsign, :birthsign, nil},
    {Resdayn.Codex.Characters.Skill, :skill, nil},
    {Resdayn.Codex.Dialogue.QuestVersion, :quest_version, nil}
  ]

  # Resources with no `name` attribute — their `id` IS the meaningful name
  # (e.g. dialogue topics, scripts, levelled lists).
  @id_indexed_resources [
    {Resdayn.Codex.Dialogue.Topic, :dialogue_topic},
    {Resdayn.Codex.Mechanics.Script, :script},
    {Resdayn.Codex.Items.ItemLevelledList, :item_levelled_list},
    {Resdayn.Codex.World.CreatureLevelledList, :creature_levelled_list}
  ]

  def rebuild do
    Resdayn.Repo.query!("TRUNCATE search_index")

    spell_task = Task.async(fn -> insert(build_spell_entries()) end)
    magic_effect_task = Task.async(fn -> insert(build_magic_effect_entries()) end)

    name_count =
      @searchable_resources
      |> Task.async_stream(
        fn resource ->
          resource
          |> build_entries()
          |> insert()
        end,
        ordered: false
      )
      |> Enum.sum_by(fn {:ok, count} -> count end)

    id_count =
      @id_indexed_resources
      |> Task.async_stream(
        fn resource ->
          resource
          |> build_id_entries()
          |> insert()
        end,
        ordered: false
      )
      |> Enum.sum_by(fn {:ok, count} -> count end)

    name_count + id_count + Task.await(spell_task) + Task.await(magic_effect_task)
  end

  defp build_entries({resource, type, icon_field}) do
    resource
    |> Ash.Query.filter(not is_nil(name) and name != "")
    |> Ash.read!()
    |> Enum.map(fn record ->
      %{
        id: "#{type}:#{record.id}",
        name: record.name,
        type: Atom.to_string(type),
        icon_filename: icon_field && Map.get(record, icon_field)
      }
    end)
  end

  defp build_id_entries({resource, type}) do
    resource
    |> Ash.read!()
    |> Enum.map(fn record ->
      %{
        id: "#{type}:#{record.id}",
        name: to_string(record.id),
        type: Atom.to_string(type),
        icon_filename: nil
      }
    end)
  end

  defp build_spell_entries do
    Resdayn.Codex.Mechanics.Spell
    |> Ash.Query.filter(not is_nil(name) and name != "")
    |> Ash.read!(load: [effects: [magic_effect: [:icon_filename]]])
    |> Enum.map(fn spell ->
      %{
        id: "spell:#{spell.id}",
        name: spell.name,
        type: "spell",
        # Store the full calculated path - controller will pass through as-is for spells
        icon_filename: spell_icon(spell.effects)
      }
    end)
  end

  # If a spell has exactly one effect, use that effect's calculated icon path
  defp spell_icon([effect]) do
    effect.magic_effect && effect.magic_effect.icon_filename
  end

  defp spell_icon(_effects), do: nil

  # Magic effects use a module calculation for `name`, so we can't filter at the
  # database level — load all and trust they have valid names.
  defp build_magic_effect_entries do
    Resdayn.Codex.Mechanics.MagicEffect
    |> Ash.Query.load([:name, :icon_filename])
    |> Ash.read!()
    |> Enum.map(fn effect ->
      %{
        id: "magic_effect:#{effect.id}",
        name: effect.name,
        type: "magic_effect",
        icon_filename: effect.icon_filename
      }
    end)
  end

  defp insert(records) do
    "search_index"
    |> Resdayn.Repo.insert_all(records)
    |> elem(0)
  end
end
