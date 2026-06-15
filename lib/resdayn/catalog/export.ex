defmodule Resdayn.Catalog.Export do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Catalog.Export.Override
  end
end
