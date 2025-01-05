defmodule Resdayn.Parser.Record.Door do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name
  process_basic_string "SNAM", :sound_open_id
  process_basic_string "ANAM", :sound_close_id
end
