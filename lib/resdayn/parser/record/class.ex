defmodule Resdayn.Parser.Record.Class do
  use Resdayn.Parser.Record

  def process(records) do
    Enum.map(records, &parse/1)
    |> Map.new()
  end

  defp parse({"CLDT", value}) do
    <<attribute_1::long(), attribute_2::long(), specialization::long(), minor_1::long(),
      major_1::long(), minor_2::long(), major_2::long(), minor_3::long(), major_3::long(),
      minor_4::long(), major_4::long(), minor_5::long(), major_5::long(), playable::long(),
      flags::long()>> = value

    {:data,
     %{
       attribute_ids: [attribute_1, attribute_2],
       specialization_id: specialization,
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
     }}
  end

  defp parse({"NAME" = v, value}) do
    {:id, printable!(__MODULE__, v, value)}
  end

  defp parse({"FNAM" = v, value}) do
    {:name, printable!(__MODULE__, v, value)}
  end

  defp parse({"DESC" = v, value}) do
    {:description, printable!(__MODULE__, v, value)}
  end
end
