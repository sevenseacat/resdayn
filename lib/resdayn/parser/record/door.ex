defmodule Resdayn.Parser.Record.Door do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
end
