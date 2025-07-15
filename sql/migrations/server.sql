CREATE TABLE `__new_server_region` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `name` text UNIQUE NOT NULL,
  `url` text NOT NULL,
  `minid` integer NOT NULL,  -- e.g., 100_000_000_000_000
  `maxid` integer NOT NULL,  -- e.g., 150_000_000_000_000
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP)
);

INSERT INTO `__new_server_region` (
  `id`,
  `name`,
  `url`,
  `minid`,
  `maxid`,
  `createdat`
)
SELECT
  `id`,
  `name`,
  `url`,
  `minid`,
  `maxid`,
  `createdat`
FROM `server_region`;

DROP TABLE `server_region`;
ALTER TABLE `__new_server_region`
RENAME TO `server_region`;


/* CREATE TABLE `__new_server_list` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `ip` text NOT NULL,
  `port` integer NOT NULL,
  `name` text NOT NULL,
  `online` boolean DEFAULT true NOT NULL,
  `players` integer DEFAULT 0 NOT NULL,
  `maxplayers` integer DEFAULT 0 NOT NULL,
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  `updatedat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  UNIQUE (`ip`, `port`),
  CHECK (`port` > -1 AND `port` < 65536)
);

INSERT INTO `__new_server_list` (
  `id`,
  `ip`,
  `port`,
  `name`,
  `online`,
  `players`,
  `maxplayers`,
  `createdat`,
  `updatedat`
)
SELECT
  `id`,
  `ip`,
  `port`,
  `name`,
  `online`,
  `players`,
  `maxplayers`,
  `createdat`,
  `updatedat`
FROM `server_list`;

DROP TABLE `server_list`;
ALTER TABLE `__new_server_list`
RENAME TO `server_list`;

CREATE INDEX `idx_server_list_ip` ON `server_list` (`ip`);
CREATE INDEX `idx_server_list_ip_port` ON `server_list` (`ip`, `port`);
CREATE INDEX `idx_server_list_online` ON `server_list` (`online`);
CREATE INDEX `idx_server_list_players` ON `server_list` (`players`);
CREATE INDEX `idx_server_list_maxplayers` ON `server_list` (`maxplayers`);
CREATE INDEX `idx_server_list_updatedat` ON `server_list` (`updatedat`); */