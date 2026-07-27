defmodule Resdayn.Exporter.Record.Book do
  @moduledoc """
  Encodes a `Resdayn.Catalog.Items.Book` resource as a BOOK record.
  """

  import Resdayn.Parser.DataSizes
  import Resdayn.Exporter.Helpers

  def encode(book, _opts) do
    weight = Decimal.to_float(book.weight)
    skill_id = book.skill_id || -1
    flags = encode_bitmask(%{scroll: book.scroll}, scroll: 0x1)

    subrecords =
      [
        {"NAME", null_terminate(book.id)},
        {"MODL", null_terminate(book.nif_model_filename)},
        {"FNAM", null_terminate(encode_string(book.name))},
        {"ITEX", null_terminate(book.icon_filename)},
        {"TEXT", encode_string(book.text)},
        {"BKDT",
         <<weight::float32(), book.value::uint32(), flags::uint32(), skill_id::uint32(),
           book.enchantment_points::uint32()>>},
        if(book.script_id, do: {"SCRI", null_terminate(book.script_id)}),
        if(book.enchantment_id, do: {"ENAM", null_terminate(book.enchantment_id)})
      ]
      |> Enum.reject(&is_nil/1)

    {"BOOK", %{}, subrecords}
  end
end
