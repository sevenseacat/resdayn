defmodule Resdayn.Catalog.Search do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Catalog.Search.SearchIndex
  end
end
