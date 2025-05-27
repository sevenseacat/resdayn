defmodule Resdayn.Importer.Record.Attribute do
  use Resdayn.Importer.Record

  def process(_records, opts) do
    # Only import the hardcoded values once, for the main Morrowind.esm file
    if opts[:filename] == "Morrowind.esm" do
      [
        %{id: 0, name: "Strength", description_game_setting_id: "sStrDesc"},
        %{id: 1, name: "Intelligence", description_game_setting_id: "sIntDesc"},
        %{id: 2, name: "Willpower", description_game_setting_id: "sWilDesc"},
        %{id: 3, name: "Agility", description_game_setting_id: "sAgiDesc"},
        %{id: 4, name: "Speed", description_game_setting_id: "sSpdDesc"},
        %{id: 5, name: "Endurance", description_game_setting_id: "sEndDesc"},
        %{id: 6, name: "Personality", description_game_setting_id: "sPerDesc"},
        %{id: 7, name: "Luck", description_game_setting_id: "sLucDesc"}
      ]
    else
      []
    end
    |> separate_for_import(Resdayn.Codex.Mechanics.Attribute)
  end
end
