defmodule Resdayn.Parser.Record.Race do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "FNAM", :name
  process_basic_string "NPCS", :special_ids
  process_basic_string "DESC", :description

  def process({"RADT", value}, data) do
    <<skills::char(56), str_m::uint32(), str_f::uint32(), int_m::uint32(), int_f::uint32(),
      wil_m::uint32(), wil_f::uint32(), agi_m::uint32(), agi_f::uint32(), spd_m::uint32(),
      spd_f::uint32(), end_m::uint32(), end_f::uint32(), per_m::uint32(), per_f::uint32(),
      luc_m::uint32(), luc_f::uint32(), height_m::float32(), height_f::float32(),
      weight_m::float32(), weight_f::float32(), flags::uint32()>> = value

    record_unnested_value(
      data,
      %{
        skill_bonuses: skills(skills),
        male_attributes: %{
          str: str_m,
          int: int_m,
          wil: wil_m,
          agi: agi_m,
          spd: spd_m,
          end: end_m,
          per: per_m,
          luc: luc_m,
          height: float(height_m),
          weight: float(weight_m)
        },
        female_attributes: %{
          str: str_f,
          int: int_f,
          wil: wil_f,
          agi: agi_f,
          spd: spd_f,
          end: end_f,
          per: per_f,
          luc: luc_f,
          height: float(height_f),
          weight: float(weight_f)
        }
      }
      |> Map.merge(bitmask(flags, playable: 1, beast: 2))
    )
  end

  defp skills(<<-1::int32(), _rest::binary>>), do: []
  defp skills(<<>>), do: []

  defp skills(<<skill::int32(), bonus::int32(), rest::binary>>) do
    [%{skill_id: skill, bonus: bonus} | skills(rest)]
  end
end
