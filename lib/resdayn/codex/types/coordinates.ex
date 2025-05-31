defmodule Resdayn.Codex.Types.Coordinates do
  @moduledoc """
  Defines a physical position, including position and direction faced, in three dimensions.

  This is used for item positions in the world, including travel destinations.
  """
  use Ash.Type.NewType,
    subtype_of: :map,
    constraints: [
      fields: [
        position: [
          type: :map,
          constraints: [
            fields: [x: [type: :decimal], y: [type: :decimal], z: [type: :decimal]]
          ]
        ],
        rotation: [
          type: :map,
          constraints: [
            fields: [
              x: [type: :decimal, constraints: [min: -180.0, max: 180.0]],
              y: [type: :decimal, constraints: [min: -180.0, max: 180.0]],
              z: [type: :decimal, constraints: [min: -180.0, max: 180.0]]
            ]
          ]
        ]
      ]
    ]
end
