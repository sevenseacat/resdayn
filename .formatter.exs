# Used by "mix format"
locals_without_parens = [process_basic_string: 2, process_basic_list: 2, process_inventory: 2]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
