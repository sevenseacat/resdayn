defmodule Resdayn.Importer.SearchIndex do
  @moduledoc """
  Rebuilds the search index from all searchable resources in the database.
  This should be run after all other imports are complete.
  """

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
    {Resdayn.Codex.Mechanics.Spell, :spell, nil},
    {Resdayn.Codex.Characters.Class, :class, nil},
    {Resdayn.Codex.Characters.Race, :race, nil},
    {Resdayn.Codex.Characters.Birthsign, :birthsign, nil},
    {Resdayn.Codex.Characters.Skill, :skill, nil}
  ]

  def rebuild do
    Resdayn.Repo.query!("TRUNCATE search_index")

    @searchable_resources
    |> Enum.flat_map(&build_entries/1)
    |> Enum.chunk_every(1000)
    |> Enum.reduce(0, fn batch, acc ->
      {inserted, _} = Resdayn.Repo.insert_all("search_index", batch, on_conflict: :nothing)
      acc + inserted
    end)
  end

  defp build_entries({resource, type, icon_field}) do
    resource
    |> Ash.read!()
    |> Enum.filter(&(&1.name && &1.name != ""))
    |> Enum.map(fn record ->
      %{
        id: "#{type}:#{record.id}",
        name: record.name,
        type: Atom.to_string(type),
        icon_filename: icon_field && Map.get(record, icon_field)
      }
    end)
  end
end
