defmodule Resdayn.Catalog.Export.EspBuilder do
  @moduledoc """
  Builds an ESP file from a set of Override records.

  Loads the actual game records referenced by the overrides and passes them
  through `Resdayn.Exporter.build/1` to produce a valid ESP binary.
  """

  @morrowind_esm_size 79_837_557

  @doc """
  Builds an ESP binary from the given Override query.

  Designed to be used as a Cinder bulk action function — accepts `(query, opts)`.
  Returns `{:ok, binary}` on success.
  """
  def run(query, _opts \\ []) do
    overrides = Ash.read!(query, load: :record)
    records = Enum.map(overrides, & &1.record)

    {:ok, binary} = Resdayn.Exporter.build([build_header() | records])
    Ash.bulk_destroy(query, :destroy, %{})
    {:ok, binary}
  end

  defp build_header do
    date = Date.utc_today() |> Calendar.strftime("%Y-%m-%d")

    %Resdayn.Catalog.Mechanics.DataFile{
      id: "library_export",
      filename: "library_export.esp",
      version: Decimal.new("1.0"),
      master: false,
      company: "Library of Morrowind",
      description: "Exported from Library on #{date}",
      dependencies: [%{filename: "Morrowind.esm", size: @morrowind_esm_size}]
    }
  end
end
