defmodule Resdayn.Parser.Record.Cell do
  use Resdayn.Parser.Record

  process_basic_string "RGNN", :region_name

  # The `NAME` for the cell itself
  def process({"NAME" = v, value}, data) when not is_map_key(data, :references) do
    record_value(data, :name, printable!(__MODULE__, v, value))
  end

  # The `DATA` for the cell itself
  def process({"DATA", value}, data) when not is_map_key(data, :references) do
    <<flags::uint32(), x::int32(), y::int32()>> = value

    record_unnested_value(data, %{
      flags:
        bitmask(flags,
          interior: 0x01,
          has_water: 0x02,
          sleeping_illegal: 0x04,
          behave_like_exterior: 0x80
        ),
      grid_position: {x, y}
    })
  end

  # Recorded on UESP as "WHGT"?? And says its a float??
  def process({"INTV", <<value::int32()>>}, data) when not is_map_key(data, :references) do
    record_value(data, :water_height, value)
  end

  def process({"WHGT", <<value::float32()>>}, data) when not is_map_key(data, :references) do
    record_value(data, :water_height, float(value))
  end

  def process({"AMBI", value}, data) do
    <<ambient::char(4), sunlight::char(4), fog::char(4), fog_density::float32()>> = value

    record_value(data, :light, %{
      ambient: color(ambient),
      sunlight: color(sunlight),
      fog: color(fog),
      fog_density: float(fog_density)
    })
  end

  def process({"NAM0", <<value::uint32()>>}, data) do
    record_value(data, :temporary_children_count, value)
  end

  def process({"NAM5", value}, data) do
    record_value(data, :map_color, color(value))
  end

  ## References in cells

  def process({"FRMR", <<value::uint32()>>}, data) do
    record_list_of_maps_key(data, :references, :id, value)
  end

  # The `NAME` for the reference in the cell
  def process({"NAME" = v, value}, data) do
    record_list_of_maps_value(data, :references, :object_id, printable!(__MODULE__, v, value))
  end

  def process({"XSCL", <<value::float32()>>}, data) do
    record_list_of_maps_value(data, :references, :scale, float(value))
  end

  # The `DATA` for the reference in the cell
  def process({"DATA", value}, data) do
    record_list_of_maps_value(data, :references, :coordinates, coordinates(value))
  end

  def process({"DODT", value}, data) do
    record_list_of_maps_value(data, :references, :cell_travel, coordinates(value))
  end

  def process({"DNAM" = v, value}, data) do
    record_list_of_maps_value(
      data,
      :references,
      :cell_travel_name,
      printable!(__MODULE__, v, value)
    )
  end

  def process({"ANAM" = v, value}, data) do
    record_list_of_maps_value(data, :references, :owner_npc_id, printable!(__MODULE__, v, value))
  end

  # The type of the value depends on the item type - we don't have that right now, so store both
  # and it can be worked out later
  # It might not be valid as one or the other though
  def process({"INTV", value}, data) do
    int =
      if match?(<<_::uint32()>>, value) do
        <<int::uint32()>> = value
        int
      else
        nil
      end

    float =
      if match?(<<_::float32()>>, value) do
        <<float::float32()>> = value
        float
      else
        nil
      end

    record_list_of_maps_value(data, :references, :remaining_usage, %{
      as_int: int,
      as_float: float
    })
  end

  def process({"NAM9", <<value::uint32()>>}, data) do
    record_list_of_maps_value(data, :references, :value, value)
  end

  def process({"FLTV", <<value::uint32()>>}, data) do
    record_list_of_maps_value(data, :references, :lock_difficulty, value)
  end

  def process({"KNAM" = v, value}, data) do
    record_list_of_maps_value(data, :references, :key_name, printable!(__MODULE__, v, value))
  end

  def process({"CNAM" = v, value}, data) do
    record_list_of_maps_value(
      data,
      :references,
      :owner_faction_id,
      printable!(__MODULE__, v, value)
    )
  end

  def process({"INDX", <<value::uint32()>>}, data) do
    record_list_of_maps_value(data, :references, :required_faction_rank, value)
  end

  def process({"TNAM" = v, value}, data) do
    record_list_of_maps_value(data, :references, :trap_name, printable!(__MODULE__, v, value))
  end

  def process({"XSOL" = v, value}, data) do
    record_list_of_maps_value(data, :references, :soul_id, printable!(__MODULE__, v, value))
  end

  def process({"BNAM" = v, value}, data) do
    record_list_of_maps_value(
      data,
      :references,
      :global_variable_id,
      printable!(__MODULE__, v, value)
    )
  end

  def process({"XCHG", <<value::float32()>>}, data) do
    record_list_of_maps_value(data, :references, :enchantment_charge, float(value))
  end

  def process({"UNAM", _}, data) do
    record_list_of_maps_value(data, :references, :blocked, true)
  end
end
