--- Chat Tables

-- Contains all chat types.
CREATE TABLE `chat_type` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `name` text UNIQUE NOT NULL -- e.g., 'emote', 'yell', 'rp', 'announce'
);

---

-- Contains all local chat messages a player sends.
CREATE TABLE `chat_local` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `sender` integer NOT NULL, -- 0 for system messages
  `message` text NOT NULL,
  `type` integer NOT NULL,
  `deleted` boolean DEFAULT false NOT NULL,
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  `deletedat` datetime,
  FOREIGN KEY (`sender`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`type`) REFERENCES `chat_type` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX `idx_chat_local_sender` ON `chat_local` (`sender`);
CREATE INDEX `idx_chat_local_type` ON `chat_local` (`type`);
CREATE INDEX `idx_chat_local_deleted` ON `chat_local` (`deleted`);
CREATE INDEX `idx_chat_local_createdat` ON `chat_local` (`createdat`);

---

-- Contains all global chat messages from admins or system.
CREATE TABLE `chat_global` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `sender` integer NOT NULL, -- 0 for system messages
  `message` text NOT NULL,
  `type` integer NOT NULL,
  `deleted` boolean DEFAULT false NOT NULL,
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  `deletedat` datetime,
  FOREIGN KEY (`sender`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`type`) REFERENCES `chat_type` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX `idx_chat_global_sender` ON `chat_global` (`sender`);
CREATE INDEX `idx_chat_global_type` ON `chat_global` (`type`);
CREATE INDEX `idx_chat_global_deleted` ON `chat_global` (`deleted`);
CREATE INDEX `idx_chat_global_createdat` ON `chat_global` (`createdat`);

---

-- Contains announcements sent to all players from admins or system.
CREATE TABLE `chat_announcement` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `sender` integer NOT NULL, -- 0 for system messages
  `message` text NOT NULL,
  `type` integer NOT NULL,
  `deleted` boolean DEFAULT false NOT NULL,
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  `deletedat` datetime,
  FOREIGN KEY (`sender`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`type`) REFERENCES `chat_type` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX `idx_chat_announcement_sender` ON `chat_announcement` (`sender`);
CREATE INDEX `idx_chat_announcement_type` ON `chat_announcement` (`type`);
CREATE INDEX `idx_chat_announcement_deleted` ON `chat_announcement` (`deleted`);
CREATE INDEX `idx_chat_announcement_createdat` ON `chat_announcement` (`createdat`);

---

-- Contains all conversations between users.
CREATE TABLE `chat_conversation` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `userid1` integer NOT NULL,
  `userid2` integer NOT NULL,
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP)
);

---

-- Contains all private messages between users.
CREATE TABLE `chat_private` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `conversationid` integer NOT NULL, -- Unique ID for the conversation
  `message` text NOT NULL,
  `type` integer NOT NULL,
  `deleted` boolean DEFAULT false NOT NULL,
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  `deletedat` datetime,
  FOREIGN KEY (`conversationid`) REFERENCES `chat_conversation` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`type`) REFERENCES `chat_type` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX `idx_chat_private_conversationid` ON `chat_private` (`conversationid`);
CREATE INDEX `idx_chat_private_type` ON `chat_private` (`type`);
CREATE INDEX `idx_chat_private_deleted` ON `chat_private` (`deleted`);
CREATE INDEX `idx_chat_private_createdat` ON `chat_private` (`createdat`);

--- TODO: BELOW HERE NEEDS WORK. | Maybe a new table for auth_accountexternal? |
--This would have temporary accounts that get deleted after their presence is gone.
-- We put their account in auth_account like normal but we store only the id in external
-- to make cleaning up easier. it also makes it easier to do some extra cascades.

-- Contains a list of all parties a user can be in.
CREATE TABLE `chat_partylist` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `owner` integer UNIQUE NOT NULL, --- TODO: WHAT ABOUT USERS FROM OTHER REGIONS?
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (`owner`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE INDEX `idx_chat_partylist_createdat` ON `chat_partylist` (`createdat`);

---

-- Contains all party members.
CREATE TABLE `chat_partymember` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `userid` integer UNIQUE NOT NULL,
  `partyid` integer NOT NULL,
  `joinedat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (`partyid`) REFERENCES `chat_partylist` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`userid`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE INDEX `idx_chat_partymember_partyid` ON `chat_partymember` (`partyid`);
CREATE INDEX `idx_chat_partymember_userid` ON `chat_partymember` (`userid`);

---
