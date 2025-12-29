defmodule Resdayn.Codex.Search do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Search.SearchIndex
  end
end
