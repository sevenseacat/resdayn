defmodule Resdayn.Importer.Record.Attribute do
  def process(_records, opts) do
    # Only import the hardcoded values once, for the main Morrowind.esm fil
    data =
      if opts[:filename] == "Morrowind.esm" do
        [
          %{id: 0, name: "Strength"},
          %{id: 1, name: "Intelligence"},
          %{id: 2, name: "Willpower"},
          %{id: 3, name: "Agility"},
          %{id: 4, name: "Speed"},
          %{id: 5, name: "Endurance"},
          %{id: 6, name: "Personality"},
          %{id: 7, name: "Luck"}
        ]
      else
        []
      end

    %{
      resource: Resdayn.Codex.Mechanics.Attribute,
      data: data
    }
  end
end
