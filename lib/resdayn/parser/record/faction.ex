defmodule Resdayn.Parser.Record.Faction do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "FNAM", :name
  process_basic_list "RNAM", :rank_names

  def process({"FADT", value}, data) do
    <<attribute_1::uint32(), attribute_2::uint32(), rankings::char(200), skills::char(28),
      flags::uint32()>> = value

    {rank_names, data} = pop_value(data, :rank_names, [])

    record_unnested_value(data, %{
      attribute_ids: [attribute_1, attribute_2],
      ranks: ranks(Enum.reverse(rank_names), rankings),
      skill_ids: skills(skills),
      hidden: flags == 1
    })
  end

  def process({"ANAM" = v, value}, data) do
    record_list_of_maps_key(data, :reactions, :target_id, printable!(__MODULE__, v, value))
  end

  def process({"INTV", <<value::int32()>>}, data) do
    record_list_of_maps_value(data, :reactions, :adjustment, value)
  end

  defp ranks([], _), do: []

  defp ranks([name | names], value) do
    <<attribute_1::uint32(), attribute_2::uint32(), skill_1::uint32(), skill_2::uint32(),
      reputation::uint32(), rest::binary>> = value

    rank = %{
      name: name,
      required_attribute_levels: [attribute_1, attribute_2],
      required_skill_levels: [skill_1, skill_2],
      required_reputation: reputation
    }

    [rank | ranks(names, rest)]
  end

  defp skills(<<-1::int32(), _rest::binary>>), do: []
  defp skills(<<>>), do: []

  defp skills(<<skill::uint32(), rest::binary>>) do
    [skill | skills(rest)]
  end
end
