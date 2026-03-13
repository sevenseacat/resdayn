defmodule Resdayn.Codex.Export do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Export.Override
  end
end
