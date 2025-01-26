defmodule Resdayn.Importer.Record.Attribute do
  def process(_records, _opts) do
    %{
      resource: Resdayn.Codex.Mechanics.Attribute,
      data: [
        %{id: 0, name: "Strength"},
        %{id: 1, name: "Intelligence"},
        %{id: 2, name: "Willpower"},
        %{id: 3, name: "Agility"},
        %{id: 4, name: "Speed"},
        %{id: 5, name: "Endurance"},
        %{id: 6, name: "Personality"},
        %{id: 7, name: "Luck"}
      ]
    }
  end
end
