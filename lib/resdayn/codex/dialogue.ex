defmodule Resdayn.Codex.Dialogue do
  use Ash.Domain, otp_app: :resdayn

  resources do
    resource __MODULE__.Quest
    resource __MODULE__.JournalEntry
    resource __MODULE__.Topic
    resource __MODULE__.Response
  end
end
