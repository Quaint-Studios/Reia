# Reia Database Schema Markdown

> This is the entire SQL schema for [Reia](https://www.playreia.com) hosted over at [Turso](https://turso.tech).

`prod_schema.db` starts here: Used as a template for all other database regions (e.g. us-east, us-west, eu-east, eu-west, etc.).

---

## **auth** (Authentication & Account Management)
| Table            | Columns                                                                                                                       | Purpose                                               |
|------------------|-------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------|
| auth_account     | id (PK), username (unique), displayname, status, steamid (unique), epicid (unique), supabaseid (unique), createdat, updatedat | Master account record, OIDC links                     |
| auth_idtype      | id (PK), name                                                                                                                 | Lookup for external ID types (steam, epic, supabase)  |
| auth_idhistory   | id (PK), userid (FK), type (FK), newid, oldid, updatedat                                                                      | History of external ID changes                        |
| auth_nametype    | id (PK), name                                                                                                                 | Lookup for name types (username, displayname)         |
| auth_namehistory | id (PK), userid (FK), type (FK), newid, oldid, updatedat                                                                      | History of name changes                               |

---

## **server** (Server, Region, Presence)
| Table            | Columns                                                                                  | Purpose                                      |
|------------------|------------------------------------------------------------------------------------------|----------------------------------------------|
| server_region    | id (PK), name (unique), url, minid, maxid, createdat                                     | Region metadata, ID sharding                 |
| server_list      | id (PK), ip, port, name, online, players, maxplayers, createdat, updatedat               | Game server registry                         |
| server_presence  | userid (PK, FK), serverid (FK), connectedat                                              | Tracks which user is on which server         |

---

## **chat** (Messaging & Communication)
| Table              | Columns                                                                                         | Purpose                                      |
|--------------------|-------------------------------------------------------------------------------------------------|----------------------------------------------|
| chat_type          | id (PK), name                                                                                   | Lookup for chat message types                |
| chat_local         | id (PK), sender (FK), message, type (FK), deleted, createdat, deletedat                         | Local (zone/area) chat                       |
| chat_global        | id (PK), sender (FK), message, type (FK), deleted, createdat, deletedat                         | Global chat (admins only)                    |
| chat_announcement  | id (PK), sender (FK), message, type (FK), deleted, createdat, deletedat                         | Announcements (admins only)                  |
| chat_conversation  | id (PK), userid1 (FK), userid2 (FK), createdat                                                  | Conversation metadata for private chat       |
| chat_private       | id (PK), conversationid (FK), message, type (FK), deleted, createdat, deletedat                 | Direct messages (private chat)               |
| chat_partylist     | id (PK), owner (FK), createdat                                                                  | Party list (party ownership)                 |
| chat_partymember   | id (PK), userid (FK), partyid (FK), joinedat                                                    | Party membership                             |

---

## **Planned/Future Modules**
| Module      | Example Tables (not yet implemented)         | Purpose/Notes                                 |
|-------------|----------------------------------------------|-----------------------------------------------|
| player      | player, player_stats, player_inventory, etc. | Player characters, stats, inventory           |
| guild       | guild, guild_member, guild_bank, etc.        | Guilds, rosters, permissions, bank            |
| economy     | transaction, auction, vendor, etc.           | Trading, auction house, vendor logs           |
| quest       | quest, player_quest, quest_objective, etc.   | Quest templates and player progress           |
| inventory   | item_template, item_instance, etc.           | Item definitions and ownership                |
| ...         | ...                                          | ...                                           |

---

## **Key Indexes & Constraints**
- All major FKs are enforced (ON DELETE CASCADE where needed)
- Indexes on search fields (e.g., username, createdat, serverid, sender)
- Triggers to prevent region ID range overlap in `server_region`

---

## **Notes**
- All IDs are region-sharded for GDPR and global uniqueness.
- Presence and authority are enforced at the server level.
- Cross-database references are handled in application logic, not SQL FKs.
- Soft deletes and audit history are implemented for moderation and compliance.
- SYSTEM sender is always `0` for messages in chat.
