defmodule Resdayn.Importer.Record.Armor do
  use Resdayn.Importer.Record

  # https://en.uesp.net/wiki/Morrowind:Medium_Armor
  @medium %{
    [:boots] => {12.0, 18.0},
    [:cuirass] => {18.0, 27.0},
    [:greaves, :shield] => {9.0, 13.5},
    [:left_bracer, :right_bracer, :left_gauntlet, :right_gauntlet, :helmet] => {3.0, 4.5},
    [:left_pauldron, :right_pauldron] => {6.0, 9.0}
  }

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Armor)
    |> Enum.map(fn record ->
      record.data
      |> Map.put(:class, class(record.data))
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Items.Armor, opts)
  end

  def class(%{type: type, weight: weight}) do
    {_, {min, max}} = Enum.find(@medium, fn {keys, _} -> type in keys end)

    cond do
      weight <= min -> :light
      weight > max -> :heavy
      true -> :medium
    end
  end
end
