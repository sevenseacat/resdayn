defmodule Resdayn.Codex.World.TransportDestination do
  use Ash.Type.NewType,
    subtype_of: :map,
    constraints: [
      fields: [
        # TODO: This *should* be a reference to a real cell but not imported yet...
        cell_name: [type: :string],
        coordinates: [
          type: :map,
          fields: [
            position: [
              type: :map,
              fields: [x: [type: :decimal], y: [type: :decimal], z: [type: :decimal]]
            ],
            rotation: [
              type: :map,
              fields: [x: [type: :decimal], y: [type: :decimal], z: [type: :decimal]]
            ]
          ]
        ]
      ]
    ]
end
