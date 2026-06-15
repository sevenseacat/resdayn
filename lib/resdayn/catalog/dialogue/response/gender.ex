defmodule Resdayn.Catalog.Dialogue.Response.Gender do
  use Ash.Type.Enum,
    values: [
      male: [label: "Male"],
      female: [label: "Female"]
    ]
end
