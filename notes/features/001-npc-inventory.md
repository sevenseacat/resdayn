# Generic Inventory System

## Plan

### Overview
Create a generic inventory system that supports NPCs, creatures, and containers with:
1. Polymorphic relationships to different item types (Tool, Clothing, Weapon, etc.)
2. Polymorphic relationships to different inventory holder types (NPC, Creature, Container)
3. Inventory metadata (count, restocking status)
4. Efficient querying in both directions (holder → items, item → holders)

### Approach
We'll create a dedicated `InventoryEntry` resource that acts as a join table between inventory holders (NPCs, creatures, containers) and items, with additional inventory-specific metadata.

#### Design Decisions
1. **Single inventory entry resource**: Rather than separate join tables for each item type or holder type, use one resource with polymorphic references
2. **Dual polymorphic pattern**: Store both item (ID + type) and holder (ID + type) to enable efficient lookups
3. **Relationships in both directions**: Add has_many relationship on all holder types and belongs_to on inventory entries

#### Schema Design
```elixir
# InventoryEntry
- id (uuid, primary_key)
- holder_id (string, references npcs/creatures/containers)
- holder_type (atom, :npc | :creature | :container)
- item_id (string, references various item tables)
- item_type (atom, specifies which item resource)
- count (integer, >= 1)
- restocking (boolean)
```

#### Resource Structure
1. **Create `Resdayn.Codex.World.InventoryEntry`**
   - Polymorphic belongs_to for holder (NPC, Creature, Container)
   - Polymorphic item reference
   - Inventory metadata fields

2. **Update `Resdayn.Codex.World.NPC`**
   - Add `has_many :inventory_entries` relationship
   - Remove current carried_objects handling

3. **Future: Update/Create Creature and Container resources**
   - Add `has_many :inventory_entries` relationship to both
   - Ensure consistent inventory interface

4. **Add item lookup functionality**
   - Actions to find any holder type carrying specific items
   - Load inventory with proper item and holder associations

#### Import Strategy
Since source data only contains item IDs without types, we need to resolve item types during import. Additionally, new items are created during the import process, so our strategy must handle dynamic item creation:

1. **Import Order Dependency**: Ensure all item types are imported before inventory holders
   ```elixir
   # Import order:
   # 1. All item resources (Tools, Clothing, Weapons, etc.)
   # 2. NPCs with inventory references
   # 3. Future: Creatures and Containers with inventory
   ```

2. **Build Item Registry**: After all items are imported, build the lookup registry
   ```elixir
   # %{"probe_apprentice_01" => :tool, "common_pants_03" => :clothing, ...}
   item_type_registry = build_item_type_registry()
   ```

3. **Type Resolution During Import**: Use the registry for O(1) item type lookups
   ```elixir
   carried_objects
   |> Enum.map(fn %{id: item_id, count: count, restocking: restocking} ->
     item_type = Map.get(item_type_registry, item_id)
     %{
       holder_id: npc_id,
       holder_type: :npc,
       item_id: item_id,
       item_type: item_type,
       count: count,
       restocking: restocking
     }
   end)
   ```

4. **Handle Missing Items**: Log warnings for item IDs that don't exist in any item resource

**Alternative Approach**: If import order is difficult to control, implement a two-pass system:
- **Pass 1**: Import all resources without inventory relationships
- **Pass 2**: Build item registry and create inventory entries

#### Implementation Steps
1. Create InventoryEntry resource with dual polymorphic relationships
2. Add domain entry for the new resource  
3. Update NPC resource with relationship
4. Create item type registry builder for import process
5. Create importer logic for NPC inventory entries with type resolution
6. Add codegen for migrations
7. Test the relationships and queries
8. Future: Extend to creatures and containers when those resources are created

#### Querying Examples
```elixir
# Get any holder's full inventory
holder |> Ash.load!(inventory_entries: [:item])

# Find all holders (NPCs, creatures, containers) carrying a specific item
InventoryEntry
|> Ash.Query.filter(item_id == "probe_apprentice_01")
|> Ash.Query.load([:holder, :item])
|> Domain.read!()

# Find only NPCs carrying a specific item
InventoryEntry
|> Ash.Query.filter(item_id == "probe_apprentice_01" and holder_type == :npc)
|> Ash.Query.load([:holder, :item])
|> Domain.read!()
```

## Log

### Implementation Progress

**Created InventoryEntry Resource** (`resdayn/lib/resdayn/codex/world/inventory_entry.ex`)
- Dual polymorphic relationships (holder_id/holder_type and item_id/item_type)
- Constraints for valid holder types (:npc, :creature, :container) and item types
- Custom actions for querying by holder or item
- Unique identity constraint to prevent duplicate entries
- Calculations for convenient item and holder access

**Updated World Domain** (`resdayn/lib/resdayn/codex/world.ex`)
- Added InventoryEntry resource to domain

**Updated NPC Resource** (`resdayn/lib/resdayn/codex/world/npc.ex`)
- Added has_many :inventory_entries relationship with filter for holder_type == :npc

**Created Item Registry System** (`resdayn/lib/resdayn/importer/item_registry.ex`)
- Builds lookup map of all item IDs to their resource types
- Converts parsed inventory data to InventoryEntry format
- Handles missing item IDs with warnings
- Supports all 9 item resource types

**Updated NPC Importer** (`resdayn/lib/resdayn/importer/record/npc.ex`)
- Uses item registry to resolve item types during import
- Returns both NPC data and InventoryEntry data
- Excludes player records from inventory processing
- Properly handles missing or empty inventory data

**Key Design Decisions Made:**
- Used dual polymorphic approach for maximum flexibility
- Identity constraint prevents duplicate inventory entries
- Inventory entries are created as separate resource data in importer
- Item registry is built once and reused for all NPCs

**Testing Results:**
- Successfully created and queried inventory entries
- Item registry built with 15,227 items across all item types
- Inventory conversion correctly handles missing items with warnings
- Polymorphic relationships work correctly for both holder and item lookups
- NPC relationship loading works as expected

**Performance Notes:**
- Registry build queries all 9 item resource types once at startup
- O(1) item type lookups during import using the registry map
- Unique constraints prevent duplicate inventory entries at database level
- Efficient querying in both directions (holder→items, item→holders)

## Conclusion

**Implementation Completed Successfully**

The generic inventory system has been fully implemented and tested. Key achievements:

1. **Flexible Architecture**: Single `InventoryEntry` resource handles all inventory scenarios
   - Dual polymorphic relationships support any holder type (NPC, future Creature/Container)
   - Supports all 9 item resource types with efficient type resolution

2. **Import Integration**: Seamless integration with existing import pipeline
   - Item type registry provides O(1) lookups for 15K+ items
   - Graceful handling of missing/invalid item references
   - Import order dependency ensures items exist before inventory creation

3. **Query Capabilities**: Efficient bidirectional querying
   - Find all items for any holder: `holder |> Ash.load!(:inventory_entries)`
   - Find all holders of specific item: `World.inventory_for_item(item_id)`
   - Type-specific filtering: `World.inventory_for_holder(id, :npc)`

4. **Extensibility**: Ready for future expansion
   - Adding Creature/Container resources only requires adding the relationship
   - Same inventory system works across all holder types
   - No schema changes needed for new item or holder types

**Next Steps for Creatures/Containers:**
When implementing these resources, simply add:
```elixir
relationships do
  has_many :inventory_entries, Resdayn.Codex.World.InventoryEntry do
    source_attribute :id
    destination_attribute :holder_id
    filter expr(holder_type == :creature)  # or :container
  end
end
```

The inventory system is production-ready and will scale efficiently for the full game world import.