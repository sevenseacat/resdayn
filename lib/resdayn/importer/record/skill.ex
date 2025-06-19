defmodule Resdayn.Importer.Record.Skill do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Skill)
    |> Enum.map(fn record ->
      record.data
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Characters.Skill, opts)
  end
end
