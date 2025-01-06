defmodule Resdayn.Parser.Record.DialogueTopic do
  use Resdayn.Parser.Record

  @dialogue_types %{
    0 => :topic,
    1 => :voice,
    2 => :greeting,
    3 => :persuasion,
    4 => :journal
  }

  process_basic_string "NAME", :id

  def process({"DATA", <<value::uint8()>>}, data) do
    record_value(data, :type, by_type(value))
  end

  def by_type(type) do
    Map.fetch!(@dialogue_types, type)
  end
end
