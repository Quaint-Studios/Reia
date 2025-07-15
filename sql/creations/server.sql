--- Server Tables

-- Contains servers. Multiple servers can be under the same IP.
-- Each server will read this table to eventually send to users.
-- If updated at has passed 5 minutes, one of them will mark it
-- with a transaction as offline.
CREATE TABLE `server_list` (
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

CREATE INDEX `idx_server_list_ip` ON `server_list` (`ip`);
CREATE INDEX `idx_server_list_ip_port` ON `server_list` (`ip`, `port`);
CREATE INDEX `idx_server_list_online` ON `server_list` (`online`);
CREATE INDEX `idx_server_list_players` ON `server_list` (`players`);
CREATE INDEX `idx_server_list_maxplayers` ON `server_list` (`maxplayers`);
CREATE INDEX `idx_server_list_updatedat` ON `server_list` (`updatedat`);

---

-- Contains all user presence on servers.
CREATE TABLE `server_presence` (
  `userid` integer PRIMARY KEY,
  `serverid` integer NOT NULL,
  `connections` integer NOT NULL,
  `connectedat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (`userid`) REFERENCES `auth_account` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (`serverid`) REFERENCES `server_list` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE INDEX `idx_server_presence_serverid` ON `server_presence` (`serverid`);
CREATE INDEX `idx_server_presence_connectedat` ON `server_presence` (`connectedat`);

---

-- Contains all possible database regions.
CREATE TABLE `server_region` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `name` text UNIQUE NOT NULL,
  `url` text NOT NULL,
  `createdat` datetime NOT NULL DEFAULT (CURRENT_TIMESTAMP)
);

CREATE TRIGGER `prevent_server_region_id_overlap`
BEFORE INSERT ON `server_region`
FOR EACH ROW
BEGIN
  -- Check for overlap with any existing region
  SELECT
    CASE
      WHEN EXISTS (
        SELECT 1 FROM `server_region`
        WHERE
          -- Overlap if new.minid <= existing.maxid AND new.maxid >= existing.minid
          NEW.minid <= maxid AND NEW.maxid >= minid
      )
      THEN
        RAISE(ABORT, 'Region ID range overlaps with existing region')
    END;
END;

CREATE TRIGGER `prevent_server_region_id_overlap_update`
BEFORE UPDATE ON `server_region`
FOR EACH ROW
BEGIN
  -- Check for overlap with any existing region except itself
  SELECT
    CASE
      WHEN EXISTS (
        SELECT 1 FROM `server_region`
        WHERE
          id != OLD.id AND
          NEW.minid <= maxid AND NEW.maxid >= minid
      )
      THEN
        RAISE(ABORT, 'Region ID range overlaps with existing region')
    END;
END;