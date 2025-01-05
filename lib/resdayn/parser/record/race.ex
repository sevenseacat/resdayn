defmodule Resdayn.Parser.Record.Race do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "FNAM", :name
  process_basic_string "NPCS", :special_ids
  process_basic_string "DESC", :description

  def process({"RADT", value}, data) do
    <<skills::char(56), str_m::long(), str_f::long(), int_m::long(), int_f::long(), wil_m::long(),
      wil_f::long(), agi_m::long(), agi_f::long(), spd_m::long(), spd_f::long(), end_m::long(),
      end_f::long(), per_m::long(), per_f::long(), luc_m::long(), luc_f::long(),
      height_m::lfloat(), height_f::lfloat(), weight_m::lfloat(), weight_f::lfloat(),
      flags::long()>> = value

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

  defp skills(<<-1::int(), _rest::binary>>), do: []
  defp skills(<<>>), do: []

  defp skills(<<skill::long(), bonus::long(), rest::binary>>) do
    [%{skill_id: skill, bonus: bonus} | skills(rest)]
  end
end
