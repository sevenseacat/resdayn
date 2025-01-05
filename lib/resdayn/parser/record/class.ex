defmodule Resdayn.Parser.Record.Class do
  use Resdayn.Parser.Record
  alias Resdayn.Parser.Record.Specialization

  process_basic_string "NAME", :id
  process_basic_string "FNAM", :name
  process_basic_string "DESC", :description

  def process({"CLDT", value}, data) do
    <<attribute_1::uint32(), attribute_2::uint32(), specialization_id::uint32(),
      minor_1::uint32(), major_1::uint32(), minor_2::uint32(), major_2::uint32(),
      minor_3::uint32(), major_3::uint32(), minor_4::uint32(), major_4::uint32(),
      minor_5::uint32(), major_5::uint32(), playable::uint32(), flags::uint32()>> = value

    record_unnested_value(data, %{
      attribute_ids: [attribute_1, attribute_2],
      specialization: Specialization.by_id(specialization_id),
      major_skill_ids: [major_1, major_2, major_3, major_4, major_5],
      minor_skill_ids: [minor_1, minor_2, minor_3, minor_4, minor_5],
      playable: playable == 1,
      vendor_for:
        bitmask(flags,
          weapons: 0x00001,
          armor: 0x00002,
          clothing: 0x00004,
          books: 0x00008,
          ingredients: 0x00010,
          picks: 0x00020,
          probes: 0x00040,
          lights: 0x00080,
          apparatus: 0x00100,
          repair_items: 0x00200,
          misc: 0x00400,
          spells: 0x00800,
          magic_items: 0x01000,
          potions: 0x02000
        ),
      services:
        bitmask(flags,
          training: 0x04000,
          spellmaking: 0x08000,
          enchanting: 0x10000,
          repairing: 0x20000
        )
    })
  end
end
