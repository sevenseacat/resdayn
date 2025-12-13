defmodule Resdayn.Codex.Items.Tool.Type do
  use Ash.Type.Enum,
    values: [
      repair_item: [label: "Repair Item"],
      lockpick: [label: "Lockpick"],
      probe: [label: "Probe"]
    ]
end
