defmodule Resdayn.Parser.Record.Birthsign do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "FNAM", :name
  process_basic_string "TNAM", :artwork_filename
  process_basic_string "DESC", :description
  process_basic_list "NPCS", :special_ids
end
