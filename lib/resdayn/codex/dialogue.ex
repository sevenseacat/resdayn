defmodule Resdayn.Codex.Dialogue do
  use Ash.Domain, otp_app: :resdayn

  resources do
    resource __MODULE__.Quest do
      define :get_quest_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.JournalEntry

    resource __MODULE__.Topic do
      define :get_topic_with_responses, action: :get_with_responses, args: [:id, :npc_id]
    end

    resource __MODULE__.Response
  end
end
