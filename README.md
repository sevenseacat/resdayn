# Resdayn

A webapp for exploring and modifying game data from The Elder Scrolls III: Morrowind.

Parses the binary ESM/ESP mod file format into a PostgreSQL database, and can export selected records back to valid ESP plugin files loadable by the game.

Using the amazing work of Dave Humphrey detailed here: http://www.uesp.net/morrow/tech/mw_esm.txt and here: https://en.uesp.net/wiki/Morrowind_Mod:Mod_File_Format

## The Plan

- [x] Parse the ESM data file into a meaningful format
- [x] Import parsed data into Ash resources in PostgreSQL
- [x] Import data from multiple files (Morrowind.esm + Tribunal.esm + Bloodmoon.esm)
- [x] Export selected records back to valid ESP plugin files
- [ ] Build a web UI for browsing and editing records
- [ ] Allow users to select modified records and download an ESP

## Record Types

| Parsed | Imported | Exported | Name |
| :---:  | :---:    | :---:    | :--: |
| ✓      | ✓        | ✓        | `TES3` (Main header) |
| ✓      | ✓        |          | `GMST` (Game settings) |
| ✓      | ✓        |          | `GLOB` (Global variable) |
| ✓      | ✓        |          | `CLAS` (Character classes) |
| ✓      | ✓        |          | `FACT` (Factions) |
| ✓      | ✓        |          | `RACE` (Races) |
| ✓      | ✓        |          | `SOUN` (Sound effects) |
| ✓      | ✓        |          | `SKIL` (Skills) |
| ✓      | ✓        |          | `MGEF` (Magic effects) |
| ✓      | ✓        |          | `SCPT` (Scripts) |
| ✓      | ✓        |          | `REGN` (Regions) |
| ✓      | ✓        |          | `BSGN` (Birth signs) |
| ✓      | x        |          | `LTEX` (Land textures) |
| ✓      | ✓        |          | `STAT` (Static objects) |
| ✓      | ✓        |          | `DOOR` (Doors) |
| ✓      | ✓        |          | `MISC` (Miscellaneous items) |
| ✓      | ✓        |          | `WEAP` (Weapons) |
| ✓      | ✓        |          | `CONT` (Containers) |
| ✓      | ✓        |          | `SPEL` (Spells) |
| ✓      | ✓        |          | `CREA` (Creatures) |
| ✓      | ✓        |          | `BODY` (Body parts) |
| ✓      | ✓        |          | `LIGH` (Lights) |
| ✓      | ✓        |          | `ENCH` (Enchanting effects) |
| ✓      | ✓        |          | `NPC_` (NPCs) |
| ✓      | ✓        |          | `ARMO` (Armor) |
| ✓      | ✓        |          | `CLOT` (Clothing) |
| ✓      | ✓        | ✓        | `REPA` (Repair items) * |
| ✓      | ✓        |          | `ACTI` (Activators) |
| ✓      | ✓        |          | `APPA` (Alchemy apparatus) |
| ✓      | ✓        | ✓        | `LOCK` (Lockpicking items) * |
| ✓      | ✓        | ✓        | `PROB` (Probe items) * |
| ✓      | ✓        |          | `INGR` (Ingredients) |
| ✓      | ✓        |          | `BOOK` (Books and papers) |
| ✓      | ✓        |          | `ALCH` (Potions) |
| ✓      | ✓        |          | `LEVI` (Item levelled list) |
| ✓      | ✓        |          | `LEVC` (Creature levelled list) |
| ✓      | ✓        |          | `CELL` (Cells) |
| x      | x        |          | `LAND` (Landscapes) |
| x      | x        |          | `PGRD` (Path grids) |
| ✓      | ✓        |          | `SNDG` (Sound generators) |
| ✓      | ✓        |          | `DIAL` (Dialogue/journal topics) |
| ✓      | ✓        |          | `INFO` (Dialogue records) |
| ✓      | ✓        |          | `INFO` (Journal records) |

## Implementation Notes

\* REPA, LOCK, and PROB records are consolidated into a single `Tool` resource with a `type` discriminator field, as they share identical data structures and serve related purposes.
