# Claude Learning Notes

This file contains critical learnings to avoid making the same mistakes again.

## Database Migrations and Foreign Key References

### Problem: Incorrect Foreign Key Target
When implementing the Region resource, I initially assumed `disturb_sleep_creature_id` referenced individual Creature records. After generating migrations and attempting import, foreign key constraints failed.

**Learning**: Always verify what records actually reference before creating relationships:
```bash
# Check what type of records IDs actually reference
mix run -e "
records = Resdayn.Parser.read(...) |> Enum.to_list()
creature_ids = records |> filter_by_type(Creature) |> get_ids()
levelled_list_ids = records |> filter_by_type(CreatureLevelledList) |> get_ids()
# Test which set contains the referenced IDs
"
```

### Problem: Migration Regeneration Process
When I discovered the foreign key was wrong, I initially tried to generate a new migration without properly cleaning up the old one.

**Learning**: When rolling back migrations to regenerate them:
1. Roll back the migration: `mix ecto.rollback`
2. Delete the migration file: `priv/repo/migrations/TIMESTAMP_*.exs`
3. Delete the snapshot file: `priv/resource_snapshots/repo/*/TIMESTAMP.json`
4. Then regenerate with `mix ash.codegen`

## Ash Type Usage

### Problem: Using Atom Constraints Instead of Enums
I initially used `constraints: [one_of: [...]]` for the sound_type attribute instead of proper Ash.Type.Enum.

**Learning**: Always use `Ash.Type.Enum` for enumerated values instead of atom constraints:
```elixir
# Wrong
attribute :sound_type, :atom, constraints: [one_of: [:left_foot, :right_foot]]

# Right
defmodule SoundType do
  use Ash.Type.Enum, values: [:left_foot, :right_foot]
end
attribute :sound_type, SoundType
```

## Embedded Resources

### Problem: Action Definitions for Embedded Resources
Embedded resources need explicit action definitions with proper accept lists, not just `defaults [:create, :update]`.

**Learning**: For embedded resources, always define actions explicitly:
```elixir
actions do
  defaults [:read]
  
  create :create do
    primary? true
    accept [:field1, :field2]
  end
  
  update :update do
    accept [:field1, :field2]
  end
end
```

## Data Structure Investigation

### Problem: Assuming Simple Data Structures
I initially assumed the sound data from the parser was a simple array of maps, but it was actually nested arrays that needed flattening.

**Learning**: Always debug parser output before writing importers:
```elixir
# Debug what the parser actually produces
records |> filter_by_type(TargetType) |> Enum.take(3) |> inspect_data_structure()
```

### Problem: Not Checking Data Dependencies
I placed Region import before its dependencies (CreatureLevelledList), causing foreign key constraint failures.

**Learning**: Always verify import order based on foreign key dependencies. Resources that reference others must be imported after their dependencies.

## Query Syntax in Mix Run Scripts

### Problem: Forgetting to Require Ash.Query
When testing relationships in `mix run` scripts, I forgot that `Ash.Query.filter` requires `require Ash.Query`.

**Learning**: Always add `require Ash.Query` at the top of scripts that use query filters:
```elixir
mix run -e "
require Ash.Query
MyResource |> Ash.Query.filter(...) |> Ash.read!()
"
```

## Custom Types and Defaults

### Problem: Complex Default Values
Custom types with complex default values (like Weather maps) can't be converted to Ecto defaults automatically, causing migration warnings.

**Learning**: For complex custom types, expect migration warnings about defaults. The migration will set defaults to `nil` and you can edit manually if needed. Consider implementing `EctoMigrationDefault` protocol if this becomes common.

## Referencable vs Non-Referencable Resources

### Learning: Not All Resources Need Referencable Extension
Some resources (like Region) are not meant to be referenced by other game objects and should not include the Referencable extension. Only add Referencable to resources that can actually be referenced in-game.

## Embedded Resources vs Custom Types

### Problem: Using Custom Types for Complex Structured Data
I initially created a Weather custom type using `Ash.Type.NewType` with map constraints, but this caused migration warnings and was less flexible than embedded resources.

**Learning**: For complex structured data with multiple fields, prefer embedded resources over custom types:

```elixir
# Less ideal - Custom type with map constraints
defmodule Weather do
  use Ash.Type.NewType,
    subtype_of: :map,
    constraints: [
      fields: [
        clear: [type: :integer, default: 0],
        cloudy: [type: :integer, default: 0]
      ]
    ]
end

# Better - Embedded resource with explicit attributes
defmodule Weather do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :clear, :integer, allow_nil?: false, default: 0, public?: true
    attribute :cloudy, :integer, allow_nil?: false, default: 0, public?: true
  end

  actions do
    defaults [:read]
    create :create do
      primary? true
      accept [:clear, :cloudy]
    end
  end
end
```

**Benefits of embedded resources:**
- Individual attributes with proper defaults that don't cause migration warnings
- Type safety and validation at the attribute level
- Better query capabilities and relationship support
- Cleaner API when accessing nested data
- No need to implement custom casting/dumping logic
</edits>