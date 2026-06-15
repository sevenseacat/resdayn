defmodule Resdayn.Importer.FactionResolver do
  @moduledoc """
  Resolves a quest-name prefix ("Imperial Cult" in
  "Imperial Cult: Buckmoth Alms") to a `Resdayn.Catalog.Characters.Faction` id.

  Each faction is indexed under its full `name` and any derived short form:

      "Great House Hlaalu" → "House Hlaalu"  (vanilla great houses)
      "Baluath Clan"       → "Baluath"       (TR Mainland clans)

  Returns `{faction_id_or_nil, rest_of_name}` so the caller gets both the
  faction and the de-prefixed name from one call. Prefixes that don't
  identify any faction ("Bounty", "College of Firewatch", etc.) return
  `nil`.

  Verified that no name or short-form collides across vanilla and TR
  Mainland factions, so a single flat lookup suffices — no per-source
  disambiguation needed.
  """

  # The one quest-prefix that doesn't match any faction.name via the
  # normal rules — a stray apostrophe.
  @aliases %{"Fighter's Guild" => "Fighters Guild"}

  def build_index do
    Resdayn.Catalog.Characters.Faction
    |> Ash.Query.select([:id, :name])
    |> Ash.read!()
    |> build_index()
  end

  def build_index(factions) do
    factions
    |> Enum.reject(&(to_string(&1.name) == "<Deprecated>"))
    |> Enum.reduce(%{}, fn faction, acc ->
      id = to_string(faction.id)
      name = to_string(faction.name)

      Enum.reduce(prefixes(name), acc, fn prefix, a ->
        Map.put_new(a, prefix, id)
      end)
    end)
  end

  defp prefixes(name) do
    short =
      cond do
        String.starts_with?(name, "Great ") -> [String.replace_prefix(name, "Great ", "")]
        String.ends_with?(name, " Clan") -> [String.replace_suffix(name, " Clan", "")]
        true -> []
      end

    [name | short]
  end

  def resolve(name, index) when is_binary(name) do
    case String.split(name, ": ", parts: 2) do
      [only] ->
        {nil, only}

      [prefix, rest] ->
        case @aliases[prefix] || Map.get(index, prefix) do
          nil -> {nil, name}
          id -> {id, rest}
        end
    end
  end
end
