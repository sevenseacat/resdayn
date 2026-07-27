defmodule Resdayn.Exporter.Record.Topic do
  @moduledoc """
  Encodes a `Resdayn.Catalog.Dialogue.Topic` resource as a DIAL record.
  """

  import Resdayn.Parser.DataSizes
  import Resdayn.Exporter.Helpers

  @type_codes %{topic: 0, voice: 1, greeting: 2, persuasion: 3, journal: 4}

  alias Resdayn.Exporter.Record.Response

  def encode(topic, _opts) do
    dial = encode_dial(topic.id, topic.type)

    infos =
      topic.responses
      |> link_responses()
      |> Enum.map(&Response.encode(&1, type: topic.type))

    [dial | infos]
  end

  defp link_responses(responses) when is_list(responses) do
    ids = Enum.map(responses, & &1.id)

    responses
    |> Enum.with_index()
    |> Enum.map(fn {response, i} ->
      %{
        response
        | previous_response_id: if(i > 0, do: Enum.at(ids, i - 1)),
          next_response_id: Enum.at(ids, i + 1)
      }
    end)
  end

  defp link_responses(_not_loaded), do: []

  def encode_dial(id, type) do
    type_code = Map.fetch!(@type_codes, type)

    subrecords = [
      {"NAME", null_terminate(id)},
      {"DATA", <<type_code::uint8()>>}
    ]

    {"DIAL", %{}, subrecords}
  end
end
