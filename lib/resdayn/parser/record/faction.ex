defmodule Resdayn.Parser.Record.Faction do
  use Resdayn.Parser.Record

  def process({"NAME" = v, value}, data) do
    record_value(data, :id, printable!(__MODULE__, v, value))
  end

  def process({"FNAM" = v, value}, data) do
    record_value(data, :name, printable!(__MODULE__, v, value))
  end

  def process({"RNAM" = v, value}, data) do
    record_list(data, :rank_names, printable!(__MODULE__, v, value))
  end

  def process({"FADT", value}, data) do
    <<attribute_1::long(), attribute_2::long(), rankings::char(200), skills::char(24), _::long(),
      flags::long()>> = value

    {rank_names, data} = pop_value(data, :rank_names, [])

    record_unnested_value(data, %{
      attribute_ids: [attribute_1, attribute_2],
      ranks: ranks(rank_names, rankings),
      skill_ids: skills(skills),
      hidden: flags == 1
    })
  end

  def process({"ANAM" = v, value}, data) do
    record_pair_key(data, :reactions, :faction, printable!(__MODULE__, v, value))
  end

  def process({"INTV", <<value::int()>>}, data) do
    record_pair_value(data, :reactions, :adjustment, value)
  end

  defp ranks([], _), do: []

  defp ranks([name | names], value) do
    <<attribute_1::long(), attribute_2::long(), skill_1::long(), skill_2::long(),
      reputation::long(), rest::binary>> = value

    rank = %{
      name: name,
      attribute_levels: [attribute_1, attribute_2],
      skill_levels: [skill_1, skill_2],
      reputation: reputation
    }

    [rank | ranks(names, rest)]
  end

  defp skills(<<-1::int(), _rest::binary>>), do: []
  defp skills(<<>>), do: []

  defp skills(<<skill::long(), rest::binary>>) do
    [skill | skills(rest)]
  end
end
