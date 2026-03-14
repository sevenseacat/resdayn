defmodule Resdayn.Codex.Types.RecordId do
  @moduledoc """
  A case-insensitive string ID for ESP/ESM records, limited to 32 characters.

  The Morrowind engine stores cross-references to records in fixed-size `char[32]`
  buffers (e.g. NPCO inventory items, NPCS spell lists). Any record ID that exceeds
  32 characters will be silently truncated by the engine.

  Exceptions that should use plain `:ci_string` instead:
  - Cell IDs (keyed by cell name, can be much longer)
  - Dialogue topic IDs (keyed by topic text, up to ~45 chars)
  - Magic effect IDs (integer, not string)
  """
  use Ash.Type.NewType,
    subtype_of: :ci_string,
    constraints: [max_length: 32]
end
