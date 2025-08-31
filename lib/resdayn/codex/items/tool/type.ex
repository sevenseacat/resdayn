defmodule Resdayn.Codex.Items.Tool.Type do
  use Ash.Type.Enum, values: [repair_item: "Repair Item", lockpick: "Lockpick", probe: "Probe"]
end
