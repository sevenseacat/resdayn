defmodule Resdayn.Importer.HelpersTest do
  use ExUnit.Case, async: true

  alias Resdayn.Importer.Helpers
  doctest Resdayn.Importer.Helpers

  describe "coordinates_to_cell_id/1" do
    @inputs [
      # The four travel destinations from Darvame Hleran (Seyda Neen caravaner)
      # Balmora
      {%{x: -21318.732, y: -18232.406, z: 1177.664}, "-3,-3"},
      # Vivec
      {%{x: 32207.215, y: -72223.805, z: 1006.437}, "3,-9"},
      # Suran
      {%{x: 53158.793, y: -48228.828, z: 984.138}, "6,-6"},
      # Gnisis
      {%{x: -86786.094, y: 89452.070, z: 1130.661}, "-11,10"},
      # Tashpi Ashibael's hut door - to Maar Gan
      {%{x: -20370.283, y: 102_760.078, z: 2056.000}, "-3,12"}
    ]

    for {input, output} <- @inputs do
      test "input #{inspect(input)} produces #{output}" do
        assert Helpers.coordinates_to_cell_id(unquote(Macro.escape(input))) == unquote(output)
      end
    end
  end
end
