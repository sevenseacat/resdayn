defmodule Resdayn.Parser.Record.Weapon do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "FNAM", :name
end
