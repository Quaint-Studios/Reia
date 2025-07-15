PRAGMA foreign_keys = OFF;

CREATE TABLE `__new_account` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `username` text NOT NULL UNIQUE,
  `displayname` text NOT NULL,
  `status` integer DEFAULT 1 NOT NULL,
  `steamid` text UNIQUE,
  `epicid` text UNIQUE,
  `supabaseid` text UNIQUE,
  `createdat` text NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedat` text NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO
  `__new_account` (
    `id`,
    `username`,
    `displayname`,
    `status`,
    `steamid`,
    `epicid`,
    `supabaseid`,
    `createdat`,
    `updatedat`
  )
SELECT
  `id`,
  `username`,
  `displayname`,
  `status`,
  `steamid`,
  `epicid`,
  `supabaseid`,
  `createdat`,
  `updatedat`
FROM
  `account`;

DROP TABLE `account`;

ALTER TABLE `__new_account`
RENAME TO `account`;

PRAGMA foreign_keys = ON;

CREATE INDEX `idx_account_createdat` ON `account` (`createdat`);
CREATE INDEX `idx_account_status` ON `account` (`status`);
CREATE INDEX `idx_account_displayname` ON `account` (`displayname`);

---

PRAGMA foreign_keys = OFF;

CREATE TABLE `__new_idhistory` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `userid` integer NOT NULL,
  `type` integer NOT NULL,
  `newid` text,
  `oldid` text,
  `updatedat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (`userid`) REFERENCES `account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`type`) REFERENCES `idtype` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
);

INSERT INTO
  `__new_idhistory` (
    `id`,
    `userid`,
    `type`
  )
SELECT
  `id`,
  `userid`,
  `type`
FROM
  `idhistory`;

DROP TABLE `idhistory`;

ALTER TABLE `__new_idhistory`
RENAME TO `idhistory`;

PRAGMA foreign_keys = ON;

CREATE INDEX `idx_idhistory_userid` ON `idhistory` (`userid`);
CREATE INDEX `idx_idhistory_type` ON `idhistory` (`type`);
CREATE INDEX `idx_idhistory_userid_type` ON `idhistory` (`userid`, `type`);

---

PRAGMA foreign_keys = OFF;
CREATE TABLE `__new_namehistory` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `userid` integer NOT NULL,
  `type` integer NOT NULL,
  `newid` text NOT NULL,
  `oldid` text NOT NULL,
  `changedat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (`userid`) REFERENCES `account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`type`) REFERENCES `nametype` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
);
INSERT INTO
  `__new_namehistory` (`id`, `userid`, `type`, `newid`, `oldid`, `changedat`)
SELECT
  `id`,
  `userid`,
  `type`,
  `newid`,
  `oldid`,
  `changedat`
FROM
  `namehistory`;
DROP TABLE `namehistory`;
ALTER TABLE `__new_namehistory`
RENAME TO `namehistory`;
PRAGMA foreign_keys = ON;

CREATE INDEX `idx_namehistory_userid` ON `namehistory` (`userid`);
CREATE INDEX `idx_namehistory_type` ON `namehistory` (`type`);
CREATE INDEX `idx_namehistory_userid_type` ON `namehistory` (`userid`, `type`);

---

CREATE TABLE `idtype` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `name` text UNIQUE NOT NULL
);

---

CREATE TABLE `nametype` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `name` text UNIQUE NOT NULL
);