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

  process_basic_string "DESC", :description

  def process({"INDX", <<value::uint32()>>}, data) do
    record_unnested_value(data, %{id: value, name: Map.fetch!(@skill_names, value)})
  end

  def process({"SKDT", value}, data) do
    <<attribute_id::uint32(), specialization::uint32(), uses::binary>> = value

    record_unnested_value(data, %{
      attribute_id: attribute_id,
      specialization: Specialization.by_id(specialization),
      uses: uses(uses)
    })
  end

  defp uses(<<>>), do: []

  defp uses(<<value::float32(), rest::binary>>) do
    [float(value) | uses(rest)]
  end
end
