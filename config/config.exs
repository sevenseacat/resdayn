import Config

config :resdayn,
  ecto_repos: [Resdayn.Repo],
  ash_domains: [
    Resdayn.Codex.Items,
    Resdayn.Codex.Assets,
    Resdayn.Codex.Characters,
    Resdayn.Codex.Mechanics,
    Resdayn.Codex.World
  ]

config :ash,
  allow_forbidden_field_for_relationships_by_default?: true,
  include_embedded_source_by_default?: false,
  show_keysets_for_all_actions?: false,
  default_page_type: :keyset,
  policies: [no_filter_static_forbidden_reads?: false]

config :spark,
  formatter: [
    remove_parens?: true,
    "Ash.Resource": [
      section_order: [
        :postgres,
        :resource,
        :code_interface,
        :actions,
        :policies,
        :pub_sub,
        :preparations,
        :changes,
        :validations,
        :multitenancy,
        :attributes,
        :relationships,
        :calculations,
        :aggregates,
        :identities
      ]
    ],
    "Ash.Domain": [section_order: [:resources, :policies, :authorization, :domain, :execution]]
  ]

config :ash, :custom_types,
  range: Resdayn.Codex.Types.Range,
  color: Resdayn.Codex.Types.Color,
  coordinates: Resdayn.Codex.Types.Coordinates,
  number: Resdayn.Codex.Types.Number

import_config "#{config_env()}.exs"
