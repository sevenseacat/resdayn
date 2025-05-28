# Unified Object References with Shared Primary Keys

## Plan

### Overview
Refactor the current polymorphic reference system (InventoryEntry, future CellReference) to use a shared primary key approach that maintains referential integrity while avoiding sparse tables. This will create a clean, type-safe system for referencing any game object while preserving the specialized resource structure.

### Problem Statement
Current polymorphic references (`item_id` + `item_type`) lose referential integrity since the database cannot enforce that the ID actually exists in the referenced table. This creates potential for orphaned references and makes data consistency harder to maintain.

### Proposed Solution
Implement a shared primary key pattern where all referenceable objects inherit from a base `ReferencableObject` table, with specialized resources maintaining the same primary key through database-level foreign key relationships.

### Architecture Design

#### 1. Object Type Enum
```elixir
defmodule Resdayn.Codex.ObjectType do
  use Ash.Type.Enum,
    values: [
      weapon: Resdayn.Codex.Items.Weapon,
      armor: Resdayn.Codex.Items.Armor,
      tool: Resdayn.Codex.Items.Tool,
      clothing: Resdayn.Codex.Items.Clothing,
      book: Resdayn.Codex.Items.Book,
      potion: Resdayn.Codex.Items.Potion,
      ingredient: Resdayn.Codex.Items.Ingredient,
      alchemy_apparatus: Resdayn.Codex.Items.AlchemyApparatus,
      miscellaneous_item: Resdayn.Codex.Items.MiscellaneousItem,
      light: Resdayn.Codex.Assets.Light,
      static_object: Resdayn.Codex.Assets.StaticObject,
      sound: Resdayn.Codex.Assets.Sound,
      npc: Resdayn.Codex.World.NPC,
      levelled_item: Resdayn.Codex.Items.LevelledItem
    ]
end
```

#### 2. Base Reference Table
```elixir
defmodule Resdayn.Codex.World.ReferencableObject do
  attributes do
    attribute :id, :string, primary_key?: true
    attribute :type, Resdayn.Codex.ObjectType, allow_nil?: false
    # NO other attributes - pure ID registry
  end
end
```

#### 3. Updated Specialized Resources
Each specialized resource maintains its current structure but adds relationship to base table:

```elixir
defmodule Resdayn.Codex.Items.Weapon do
  attributes do
    attribute :id, :string, primary_key?: true  # Same ID as ReferencableObject
    # All existing weapon-specific attributes unchanged
  end

  relationships do
    belongs_to :referencable_object, Resdayn.Codex.World.ReferencableObject,
      source_attribute: :id,
      destination_attribute: :id,
      define_attribute?: false
  end

  # Ensure ReferencableObject entry is created/updated
  changes do
    change after_action(fn changeset, weapon, _context ->
      Resdayn.Codex.World.ReferencableObject.create!(%{
        id: weapon.id,
        type: :weapon
      })
      {:ok, weapon}
    end), on: [:create]
  end
end
```

#### 4. Simplified Reference Tables
```elixir
defmodule Resdayn.Codex.World.InventoryEntry do
  attributes do
    attribute :id, :uuid, primary_key?: true
    attribute :count, :integer, allow_nil?: false, constraints: [min: 1]
    attribute :restocking, :boolean, allow_nil?: false, default: false
  end

  relationships do
    belongs_to :holder, Resdayn.Codex.World.ReferencableObject, allow_nil?: false
    belongs_to :item, Resdayn.Codex.World.ReferencableObject, allow_nil?: false
  end

  calculations do
    calculate :typed_holder, :map, {__MODULE__.Calculations.TypedHolder, []}
    calculate :typed_item, :map, {__MODULE__.Calculations.TypedItem, []}
  end
end



#### 5. Typed Object Calculations
```elixir
defmodule Resdayn.Codex.Calculations.TypedObject do
  use Ash.Resource.Calculation

  def load(_query, _opts, _context) do
    [:object]  # Ensure ReferencableObject is loaded
  end

  def calculate(records, _opts, _context) do
    # Group by object type for efficient batch loading
    by_type = Enum.group_by(records, fn record ->
      record.object.type
    end)

    # Load each type in batch
    typed_objects =
      Enum.flat_map(by_type, fn {type, entries} ->
        object_ids = Enum.map(entries, &(&1.object.id))
        resource = Resdayn.Codex.ObjectType.values()[type]

        objects =
          resource
          |> Ash.Query.filter(id in ^object_ids)
          |> Resdayn.Codex.read!()

        Enum.map(objects, &{&1.id, &1})
      end)
      |> Map.new()

    # Return in same order as input records
    Enum.map(records, fn record ->
      Map.get(typed_objects, record.object.id)
    end)
  end
end
```

### Migration Strategy

#### Phase 1: Create Base Infrastructure
1. Create `ReferencableObject` resource and table
2. Create shared calculation modules for typed object loading
3. Add domain entries for new resources

#### Phase 2: Update Specialized Resources
1. Add `belongs_to :referencable_object` relationships to all item/object resources
2. Add after_action hooks to create/update ReferencableObject entries
3. Generate migrations for foreign key constraints

#### Phase 3: Populate Base Table
1. Create migration to populate `referencable_objects` table from existing resources
2. Add foreign key constraints between specialized tables and base table
3. Verify referential integrity

#### Phase 4: Update Reference Systems
1. Update `InventoryEntry` to use ReferencableObject foreign keys
2. Add typed object calculations to InventoryEntry
3. Remove old polymorphic `item_id`/`item_type` columns

#### Phase 5: Update Import System
1. Modify importers to create ReferencableObject entries alongside specialized objects
2. Update InventoryEntry importer to use ReferencableObject references
3. Remove item registry system (no longer needed)

### Benefits
1. **Referential Integrity**: Database-enforced foreign keys prevent orphaned references
2. **Clean Schema**: No sparse tables with many nullable columns
3. **Type Safety**: Specialized resources maintain all their type-specific validations
4. **Efficient Queries**: Batch loading of typed objects minimizes N+1 queries
5. **Unified Interface**: All reference systems work the same way
6. **Extensible**: Easy to add new object types by implementing the same pattern

### Usage Examples
```elixir
# Get NPC's full inventory with typed objects
npc = Resdayn.Codex.World.get_npc!("fargoth")
inventory =
  Resdayn.Codex.World.InventoryEntry
  |> Ash.Query.filter(holder.id == ^npc.id and holder.type == :npc)
  |> Ash.Query.load(:typed_item)
  |> Resdayn.Codex.World.read!()

# inventory entries now have .typed_item with actual Weapon/Armor/etc structs

# Pattern match on typed objects
Enum.each(inventory, fn entry ->
  case entry.typed_item do
    %Resdayn.Codex.Items.Weapon{name: name, chop_magnitude: damage} ->
      IO.puts("Weapon #{name} (#{damage} chop damage) x#{entry.count}")
    %Resdayn.Codex.Items.Armor{name: name, armor_rating: rating} ->
      IO.puts("Armor #{name} (#{rating} protection) x#{entry.count}")
    _ ->
      IO.puts("Item #{entry.typed_item.name} x#{entry.count}")
  end
end)
```

### Implementation Order
1. Create ObjectType enum and ReferencableObject resource
2. Create shared TypedObject calculation module
3. Update one specialized resource (e.g., Weapon) as proof of concept
4. Verify foreign key relationships and calculations work correctly
5. Update all remaining specialized resources in batch
6. Populate ReferencableObject table with existing data
7. Update InventoryEntry to use new reference system
8. Update import system to work with new architecture
9. Remove old polymorphic reference columns and related code

### Testing Strategy
- Unit tests for ReferencableObject creation/updates
- Integration tests for typed object calculations
- Performance tests for batch loading efficiency
- Migration tests to ensure data integrity during transition
- End-to-end tests for common usage patterns (inventory loading, cell object queries)

## Log

### Proof of Concept Implementation

**Created Base Infrastructure** ✅
- Created `Resdayn.Codex.ObjectType` enum with type-to-resource mapping
- Created `Resdayn.Codex.World.ReferencableObject` resource
- Created shared `Resdayn.Codex.Calculations.TypedObject` calculation module
- Added main `Resdayn.Codex` domain for cross-domain resources
- Generated and ran migration successfully

**Updated Weapon Resource** ✅
- Added `belongs_to :referencable_object` relationship with shared primary key
- Added after_action hook to create ReferencableObject entries on weapon creation
- Migration creates proper foreign key constraint from weapons.id to referencable_objects.id

**Testing Findings** ⚠️
- Database migration successful - foreign key constraints properly enforced
- Weapon creation fails as expected due to referential integrity constraint
- Error: "Invalid value provided for id: does not exist" because ReferencableObject doesn't exist yet
- This confirms the foreign key constraint is working correctly

**Issue Identified: After-Action Hook Timing**
The current after_action hook runs after the database INSERT, but the foreign key constraint is checked during the INSERT. We need to create the ReferencableObject entry BEFORE the specialized resource is inserted.

**Solutions to Consider:**
1. **Before-action hook**: Create ReferencableObject in before_action instead of after_action
2. **Single transaction**: Use before_transaction to create ReferencableObject
3. **Upsert approach**: Use database UPSERT to handle conflicts gracefully

**Proof of Concept Success** ✅
**Fixed Timing Issue**:
- Changed from `after_action` to `before_action` hook to create ReferencableObject before weapon insertion
- Added explicit `create` action to ReferencableObject that accepts `[:id, :type]`
- Hook only runs for `import_create` actions to avoid conflicts with other creation methods

**Test Results**:
```sql
-- 1. ReferencableObject created first (maintains referential integrity)
INSERT INTO "referencable_objects" ("id","type") VALUES ("test_sword", :weapon)

-- 2. Weapon created second with foreign key constraint satisfied
INSERT INTO "weapons" (...) VALUES (..., "test_sword", ...)

-- 3. Transaction committed successfully - no constraint violations
```

**Verification**:
- ✅ Weapon created successfully with ID "test_sword"
- ✅ ReferencableObject created with matching ID and type `:weapon`
- ✅ Foreign key constraint `weapons.id -> referencable_objects.id` enforced
- ✅ Database referential integrity maintained
- ✅ Before-action hook timing works perfectly

**Reusable Change Module** ✅
**Created Shared Pattern**:
- Created `Resdayn.Codex.Changes.CreateReferencableObject` change module
- Accepts `object_type` option to specify the type (`:weapon`, `:armor`, etc.)
- Only runs for `import_create` actions to avoid conflicts
- Validates required `object_type` option at init time

**Implementation**:
```elixir
# Usage in any specialized resource:
changes do
  change {Resdayn.Codex.Changes.CreateReferencableObject, object_type: :weapon}, on: [:create]
end

# Creates ReferencableObject before specialized resource insertion
# Maintains referential integrity automatically
```

**Test Results**:
- ✅ Weapon resource updated to use reusable change module
- ✅ ReferencableObject creation works identically to custom hook
- ✅ Clean, declarative syntax for adding to other resources
- ✅ Type validation ensures correct object_type values
- ✅ Pattern ready for rollout to all specialized resources

**Rollout to All Resources** ✅
**Applied Unified Pattern**:
- Updated all 14 referenceable resource types with shared primary key relationships
- Added `CreateReferencableObject` change to: Weapon, Armor, Tool, Clothing, Book, Potion, Ingredient, AlchemyApparatus, MiscellaneousItem, Light, StaticObject, Sound, NPC, ItemLevelledList
- Generated migration with foreign key constraints for all specialized tables
- All constraints point to `referencable_objects.id` maintaining referential integrity

**Full Import Test Results** 🎉
**Successfully imported complete Morrowind.esm dataset**:
```
ReferencableObject counts by type:
  alchemy_apparatus: 22
  armor: 280
  book: 574
  clothing: 510
  ingredient: 95
  item_levelled_list: 227
  light: 574
  miscellaneous_item: 536
  npc: 2674
  potion: 258
  sound: 430
  static_object: 2788
  tool: 18
  weapon: 487
  TOTAL: 9,473 objects with full referential integrity
```

**Import Performance**:
- ✅ Zero constraint violations - all 9,473 objects created successfully
- ✅ ReferencableObject entries created before specialized resources
- ✅ Foreign key constraints enforced at database level
- ✅ Pattern scales to full game dataset (nearly 10,000 objects)
- ⚠️ Ash notification warnings (harmless, can be configured away)

**Architecture Validated**:
- Shared primary key approach works at scale
- Reusable change module successfully applied across all domains
- Database referential integrity maintained without sparse tables
- Clean separation between base registry and specialized data

**Next Steps:**
1. Update InventoryEntry to use ReferencableObject references ➡️
2. Test TypedObject calculation with real data ➡️
3. Create new cell reference system using same pattern
4. Phase out old polymorphic reference systems
