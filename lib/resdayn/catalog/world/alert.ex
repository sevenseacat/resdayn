defmodule Resdayn.Catalog.World.Alert do
  use Ash.Type.NewType,
    subtype_of: :map,
    constraints: [
      fields: [
        hello: [type: :integer],
        alarm: [type: :integer],
        fight: [type: :integer],
        flee: [type: :integer]
      ]
    ]
end
