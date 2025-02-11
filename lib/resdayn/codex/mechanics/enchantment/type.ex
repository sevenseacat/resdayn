defmodule Resdayn.Codex.Mechanics.Enchantment.Type do
  use Ash.Type.Enum, values: [:cast_once, :cast_when_used, :cast_on_strike, :constant_effect]
end
