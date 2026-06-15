defmodule Resdayn.Exporter.Record.Script do
  @moduledoc """
  Encodes a `Resdayn.Catalog.Mechanics.Script` resource as a SCPT record.

  If `start_script: true`, also emits an SSCR record so the engine
  registers the script as auto-running.

  Note: this encoder writes only the human-readable script source (SCTX) —
  no compiled bytecode (SCDT). OpenMW recompiles at load time, so the
  ESP works there but not in vanilla Morrowind.
  """

  import Resdayn.Parser.DataSizes
  import Resdayn.Exporter.Helpers

  def encode(script) do
    locals = script.local_variables || []
    {num_shorts, num_longs, num_floats} = count_variable_types(script.text)

    scvr_data = build_scvr(locals)

    schd =
      <<pad_string(script.id, 32)::binary, num_shorts::uint32(), num_longs::uint32(),
        num_floats::uint32(), 0::uint32(), byte_size(scvr_data)::uint32()>>

    subrecords =
      [
        {"SCHD", schd},
        if(scvr_data != "", do: {"SCVR", scvr_data}),
        {"SCTX", encode_string(script.text)}
      ]
      |> Enum.reject(&is_nil/1)

    scpt = {"SCPT", %{}, subrecords}

    if script.start_script do
      sscr = {"SSCR", %{}, [{"NAME", null_terminate(script.id)}, {"DATA", <<0::uint32()>>}]}
      [scpt, sscr]
    else
      scpt
    end
  end

  # Local variable names are stored as a single null-separated string with a
  # trailing null terminator. Empty list → empty string (no SCVR subrecord).
  defp build_scvr([]), do: ""
  defp build_scvr(names), do: Enum.map_join(names, <<0>>, & &1) <> <<0>>

  # Count variable declarations by type from the script source.
  # Matches "short X", "long X", "float X" at the start of a line (with optional whitespace).
  defp count_variable_types(text) do
    text
    |> String.split("\n")
    |> Enum.reduce({0, 0, 0}, fn line, {s, l, f} ->
      case String.trim(line) do
        "short " <> _ -> {s + 1, l, f}
        "long " <> _ -> {s, l + 1, f}
        "float " <> _ -> {s, l, f + 1}
        _ -> {s, l, f}
      end
    end)
  end
end
