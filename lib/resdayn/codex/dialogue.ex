defmodule Resdayn.Codex.Dialogue do
  use Ash.Domain, otp_app: :resdayn

  resources do
    resource __MODULE__.Quest
    resource __MODULE__.JournalEntry
  end
end
