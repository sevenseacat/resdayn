defmodule Resdayn.Importer.Record.Activator do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Activator)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :name, :script_id, :nif_model_filename])
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Assets.Activator,
      data: data
    }
  end
end
