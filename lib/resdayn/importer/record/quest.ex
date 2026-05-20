defmodule Resdayn.Importer.Record.Quest do
  require Ash.Query
  import Ecto.Query

  @doc """
  Rebuild the top-level Quest resource data, collecting together all of the
  quests with the same name, such as "Sleepers Awake" or "Imperial Cult: Buckmoth Arms"

  Uses raw Ecto even though there's not many records, because I don't really want
  to have to add actions to the resources for this special case
  """
  def collate do
    # Drop the existing links
    Resdayn.Repo.update_all(from(q in "quest_versions"), set: [quest_id: nil])
    Resdayn.Repo.delete_all(from(q in "quests"))

    index = Resdayn.Importer.FactionResolver.build_index()

    Resdayn.Codex.Dialogue.QuestVersion
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(not is_nil(name))
    |> Ash.read!()
    |> Enum.group_by(& &1.name)
    |> Enum.map(fn {name, quest_versions} ->
      {faction_id, suffix} = Resdayn.Importer.FactionResolver.resolve(name, index)

      source_files =
        quest_versions
        |> Enum.flat_map(& &1.source_file_ids)
        |> Enum.uniq()

      id = slug(name)
      insert_quest(%{id: id, name: suffix, faction_id: faction_id, source_file_ids: source_files})
      update_versions(id, quest_versions)
    end)
    |> length()
  end

  defp slug(name) do
    name
    |> String.downcase()
    |> String.replace(~r/['']/, "")
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp insert_quest(quest) do
    Resdayn.Repo.insert_all("quests", [quest])
  end

  defp update_versions(quest_id, versions) do
    from(q in "quest_versions", where: q.id in ^Enum.map(versions, &to_string(&1.id)))
    |> Resdayn.Repo.update_all(set: [quest_id: quest_id])
  end
end
