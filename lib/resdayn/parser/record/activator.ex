defmodule Resdayn.Parser.Record.Activator do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model_filename
  process_basic_string "FNAM", :name
  process_basic_string "SCRI", :script_id
end
