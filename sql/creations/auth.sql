--- Auth Tables

-- Contains all local user accounts.
CREATE TABLE `auth_accountinfo` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `username` text NOT NULL UNIQUE,
  `displayname` text NOT NULL,
  `status` integer DEFAULT 1 NOT NULL,
  `steamid` text UNIQUE,
  `epicid` text UNIQUE,
  `supabaseid` text UNIQUE,
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  `updatedat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP)
);

CREATE INDEX `idx_auth_accountinfo_displayname` ON `auth_accountinfo` (`displayname`);
CREATE INDEX `idx_auth_accountinfo_status` ON `auth_accountinfo` (`status`);
CREATE INDEX `idx_auth_accountinfo_createdat` ON `auth_accountinfo` (`createdat`);

---

-- Contains all users that have connected to this database.
CREATE TABLE `auth_account` (
  `id` integer PRIMARY KEY,
  `isexternal` boolean NOT NULL DEFAULT 0,
  FOREIGN KEY (`id`) REFERENCES `auth_accountinfo` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE INDEX `idx_auth_account_isexternal` ON `auth_account` (`isexternal`);

---

-- enum: steam, epic, supabase
CREATE TABLE `auth_idtype` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `name` text UNIQUE NOT NULL
);

---

-- Contains all ID history for users.
CREATE TABLE `auth_idhistory` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `userid` integer NOT NULL,
  `type` integer NOT NULL,
  `newid` text,
  `oldid` text,
  `updatedat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (`userid`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`type`) REFERENCES `auth_idtype` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX `idx_auth_idhistory_userid` ON `auth_idhistory` (`userid`);
CREATE INDEX `idx_auth_idhistory_type` ON `auth_idhistory` (`type`);
CREATE INDEX `idx_auth_idhistory_userid_type` ON `auth_idhistory` (`userid`, `type`);

---

-- enum: username, displayname
CREATE TABLE `auth_nametype` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `name` text UNIQUE NOT NULL
);

---

-- Contains all name history for users.
CREATE TABLE `auth_namehistory` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `userid` integer NOT NULL,
  `type` integer NOT NULL,
  `newid` text NOT NULL,
  `oldid` text NOT NULL,
  `updatedat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (`userid`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`type`) REFERENCES `auth_nametype` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX `idx_auth_namehistory_userid` ON `auth_namehistory` (`userid`);
CREATE INDEX `idx_auth_namehistory_type` ON `auth_namehistory` (`type`);
CREATE INDEX `idx_auth_namehistory_userid_type` ON `auth_namehistory` (`userid`, `type`);
