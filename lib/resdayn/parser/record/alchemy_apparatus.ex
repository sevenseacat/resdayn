defmodule Resdayn.Parser.Record.AlchemyApparatus do
  use Resdayn.Parser.Record

  @apparatus_types %{
    0 => :mortar_and_pestle,
    1 => :alembic,
    2 => :calcinator,
    3 => :retort
  }

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon
  process_basic_string "SCRI", :script_id

  def process({"AADT", value}, data) do
    <<type::uint32(), quality::float32(), weight::float32(), value::uint32()>> = value

    record_unnested_value(data, %{
      type: Map.fetch!(@apparatus_types, type),
      quality: quality,
      weight: weight,
      value: value
    })
  end
end
