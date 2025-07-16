--- Friend Tables
--  # Between regions, friend tables are shared. It would create it on both regions.

-- Tracks friend requests between users.
CREATE TABLE `player_friendrequest` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `sender` integer NOT NULL,      -- FK to auth_account(id)
  `receiver` integer NOT NULL,    -- FK to auth_account(id)
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (`sender`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`receiver`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE INDEX `idx_player_friendrequest_sender` ON `player_friendrequest` (`sender`);
CREATE INDEX `idx_player_friendrequest_receiver` ON `player_friendrequest` (`receiver`);
CREATE INDEX `idx_player_friendrequest_createdat` ON `player_friendrequest` (`createdat`);

---

-- Tracks accepted friendships between users.
CREATE TABLE `player_friendship` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `userid1` integer NOT NULL,     -- FK to auth_account(id)
  `userid2` integer NOT NULL,     -- FK to auth_account(id)
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (`userid1`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`userid2`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  UNIQUE (`userid1`, `userid2`) -- if userid2 friends userid1, the first to accept will remove both entries.
);

CREATE INDEX `idx_player_friendship_userid1` ON `player_friendship` (`userid1`);
CREATE INDEX `idx_player_friendship_userid2` ON `player_friendship` (`userid2`);
CREATE INDEX `idx_player_friendship_createdat` ON `player_friendship` (`createdat`);
---

-- Tracks blocks between users.
CREATE TABLE `player_friendblock` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `userid1` integer NOT NULL,     -- FK to auth_account(id), blocker
  `userid2` integer NOT NULL,     -- FK to auth_account(id), blocked
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (`userid1`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`userid2`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  UNIQUE (`userid1`, `userid2`)
);

CREATE INDEX `idx_player_friendblock_userid1` ON `player_friendblock` (`userid1`);
CREATE INDEX `idx_player_friendblock_userid2` ON `player_friendblock` (`userid2`);
CREATE INDEX `idx_player_friendblock_createdat` ON `player_friendblock` (`createdat`);

--- Lookup table for friendship actions
CREATE TABLE `player_friendactiontype` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `name` text UNIQUE NOT NULL    -- e.g., 'request', 'accept', 'block', 'unblock', 'remove'
);

---

-- Tracks friendship actions/events for history.
CREATE TABLE `player_friendlog` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `userid1` integer NOT NULL,     -- FK to auth_account(id)
  `userid2` integer NOT NULL,     -- FK to auth_account(id)
  `action` integer NOT NULL,      -- FK to player_friendactiontype(id)
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (`userid1`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`userid2`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`action`) REFERENCES `player_friendactiontype` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX `idx_player_friendlog_userid1` ON `player_friendlog` (`userid1`);
CREATE INDEX `idx_player_friendlog_userid2` ON `player_friendlog` (`userid2`);
CREATE INDEX `idx_player_friendlog_action` ON `player_friendlog` (`action`);
CREATE INDEX `idx_player_friendlog_createdat` ON `player_friendlog` (`createdat`);

--- Stats Tables

-- Contains player statistics.
CREATE TABLE `player_stats` (
  `id` integer PRIMARY KEY,
  -- Combat Stats
  `health` integer NOT NULL DEFAULT 1, -- Increases health pool by 100 each level, also combos with spirits
  `ether` integer NOT NULL DEFAULT 1, -- Increases mana pool by 50 each level, also combos with spirits and magic damage and unlocks magic skills
  `attack` integer NOT NULL DEFAULT 1, -- Unlocks sections in sub skills. Also can increase critical hit chance and ranged damage.
  `strength` integer NOT NULL DEFAULT 1, -- Improves both physical damage and ranged damage.
  `defense` integer NOT NULL DEFAULT 1, -- Has focus on sub skills like tank, agile, and also improves damage mitigation.

  -- Crafting Stats
  --- The skills below are for the future designs. Maybe a separate table?
  /* `smithing` integer NOT NULL DEFAULT 1, -- Improves weapon quality and unlocks weapon crafting skills.
  `tailoring` integer NOT NULL DEFAULT 1, -- Improves clothing quality and unlocks clothing crafting skills.
  `alchemy` integer NOT NULL DEFAULT 1, -- Improves potion quality and unlocks potion crafting skills.
  `cooking` integer NOT NULL DEFAULT 1, -- Improves food quality and cooking efficiency. Also unlocks cooking skills.
  `enchanting` integer NOT NULL DEFAULT 1, -- Improves enchantment quality and unlocks enchanting skills.

  -- Resource Gathering Stats
  `mining` integer NOT NULL DEFAULT 1, -- Improves mining efficiency and unlocks mining skills.
  `fishing` integer NOT NULL DEFAULT 1, -- Improves fishing efficiency and unlocks better fish you can capture.
  `farming` integer NOT NULL DEFAULT 1, -- Improves crop yield and farming efficiency. Also unlocks farming skills.
  `hunting` integer NOT NULL DEFAULT 1, -- Improves hunting efficiency and unlocks hunting skills.

  -- Utility Stats
  `trading` integer NOT NULL DEFAULT 1, -- Improves trading efficiency and unlocks trading skills. Also effective on island trading.
  `sailing` integer NOT NULL DEFAULT 1, -- Improves sailing your flying ship and unlocks ship upgrades. Also unlocks sailing sub skills.

  -- Island Skills
  `exploration` integer NOT NULL DEFAULT 1,
  `management` integer NOT NULL DEFAULT 1, -- Improves island management, NPC hiring, automation, and resource gathering efficiency. */
  `updatedat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),

  FOREIGN KEY (`id`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
);

---

-- Contains player inventory.
CREATE TABLE `player_inventory` (
  `id` integer PRIMARY KEY,
  `itemid` integer NOT NULL, -- FK to item table
  `quantity` integer NOT NULL DEFAULT 1,
  FOREIGN KEY (`id`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE INDEX `idx_player_inventory_itemid` ON `player_inventory` (`id`, `itemid`);