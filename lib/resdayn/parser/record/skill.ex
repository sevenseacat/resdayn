defmodule Resdayn.Parser.Record.Skill do
  use Resdayn.Parser.Record
  alias Resdayn.Parser.Record.Specialization

  @skill_names %{
    0 => "Block",
    1 => "Armorer",
    2 => "Medium Armor",
    3 => "Heavy Armor",
    4 => "Blunt Weapon",
    5 => "Long Blade",
    6 => "Axe",
    7 => "Spear",
    8 => "Athletics",
    9 => "Enchant",
    10 => "Destruction",
    11 => "Alteration",
    12 => "Illusion",
    13 => "Conjuration",
    14 => "Mysticism",
    15 => "Restoration",
    16 => "Alchemy",
    17 => "Unarmored",
    18 => "Security",
    19 => "Sneak",
    20 => "Acrobatics",
    21 => "Light Armor",
    22 => "Short Blade",
    23 => "Marksman",
    24 => "Mercantile",
    25 => "Speechcraft",
    26 => "Hand to Hand"
  }

  def process({"INDX", <<value::int()>>}, data) do
    record_unnested_value(data, %{id: value, name: Map.fetch!(@skill_names, value)})
  end

  def process({"SKDT", value}, data) do
    <<attribute_id::long(), specialization::long(), uses::binary>> = value

    record_unnested_value(data, %{
      attribute_id: attribute_id,
      specialization: Specialization.by_id(specialization),
      uses: uses(uses)
    })
  end

  def process({"DESC" = v, value}, data) do
    record_value(data, :description, printable!(__MODULE__, v, value))
  end

  defp uses(<<>>), do: []

  defp uses(<<value::lfloat(), rest::binary>>) do
    [float(value) | uses(rest)]
  end
end
