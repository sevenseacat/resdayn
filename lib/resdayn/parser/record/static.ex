defmodule Resdayn.Parser.Record.Static do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model_filename
end
