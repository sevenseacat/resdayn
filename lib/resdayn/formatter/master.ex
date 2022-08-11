defmodule Resdayn.Formatter.Master do
  @moduledoc """
  The master record, defining properties of the data file itself.
  """
  import Resdayn.Formatter.Helpers

  def format(record) do
    %{
      flags: flags,
      subrecords: [
        {"HEDR",
         %{
           company: company,
           description: description,
           record_count: record_count,
           version: version
         }}
        | dependencies
      ]
    } = record

    dependencies =
      dependencies
      |> Enum.chunk_every(2)
      |> Enum.map(fn [{"MAST", name}, {"DATA", size}] -> %{name: name, size: size} end)

    %{
      type: :master,
      company: company,
      description: fix_newlines(description),
      record_count: record_count,
      version: version,
      dependencies: dependencies,
      flags: flags
    }
  end
end
