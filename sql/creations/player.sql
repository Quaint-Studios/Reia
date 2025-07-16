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

