defmodule Resdayn.Parser.HelpersTest do
  use ExUnit.Case, async: true

  alias Resdayn.Parser.Helpers
  doctest Resdayn.Parser.Helpers

  describe "float_to_short/1" do
    @inputs [
      # Day
      {<<0, 0, 128, 65>>, 16},
      # Month
      {<<0, 0, 224, 64>>, 7},
      # Year
      {<<0, 128, 213, 67>>, 427},
      # NPCVoiceDistance
      {<<0, 128, 59, 68>>, 750},
      # OwnershipHHCS
      {<<0, 0, 128, 63>>, 1},
      # Everything else is zero
      {"\r\nGo", 0},
      {"8ȝ\t", 0},
      {"dif\r", 0},
      {"f\r\n\r", 0},
      {"r Ga", 0},
      {"rest", 0},
      {"t le", 0},
      {"up =", 0},
      {"you ", 0},
      {<<0, 108, 46, 0>>, 0},
      {<<0, 70, 58, 3>>, 0},
      {<<101, 110, 116, 0>>, 0},
      {<<101, 95, 113, 0>>, 0},
      {<<108, 108, 32, 0>>, 0},
      {<<110, 101, 33, 0>>, 0},
      {<<112, 138, 194, 0>>, 0},
      {<<112, 194, 46, 5>>, 0},
      {<<114, 46, 0, 0>>, 0},
      {<<115, 101, 46, 0>>, 0},
      {<<117, 110, 99, 0>>, 0},
      {<<144, 231, 178, 0>>, 0},
      {<<152, 40, 222, 5>>, 0},
      {<<16, 0, 0, 0>>, 0},
      {<<160, 55, 195, 0>>, 0},
      {<<231, 0, 0, 0>>, 0},
      {<<255, 255, 255, 255>>, 0},
      {<<32, 104, 101, 0>>, 0},
      {<<46, 0, 0, 0>>, 0},
      {<<48, 40, 197, 0>>, 0},
      {<<5, 1, 115, 4>>, 0},
      {<<80, 53, 197, 0>>, 0},
      {<<96, 75, 106, 1>>, 0}
    ]
    for {input, output} <- @inputs do
      test "input #{inspect(input)} produces #{output}" do
        assert Helpers.float_to_short(unquote(input)) == unquote(output)
      end
    end
  end
end
