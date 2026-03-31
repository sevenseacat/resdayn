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
    {Resdayn.Codex.Characters.Faction, :faction, nil},
    {Resdayn.Codex.Characters.Class, :class, nil},
    {Resdayn.Codex.Characters.Race, :race, nil},
    {Resdayn.Codex.Characters.Birthsign, :birthsign, nil},
    {Resdayn.Codex.Characters.Skill, :skill, nil}
  ]

  def rebuild do
    Resdayn.Repo.query!("TRUNCATE search_index")

    spell_task = Task.async(fn -> insert(build_spell_entries()) end)

    count =
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

    count + Task.await(spell_task)
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

  defp insert(records) do
    "search_index"
    |> Resdayn.Repo.insert_all(records)
    |> elem(0)
  end
end
