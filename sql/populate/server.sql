INSERT INTO `server_region` (`name`, `url`, `minid`, `maxid`) VALUES (
  'us-east', 
  'libsql://prod-quaintstudios.aws-us-east-1.turso.io',
  100000000000000,
  149999999999999
);

INSERT INTO `server_list` (
  `ip`,
  `port`,
  `name`
) VALUES (
  '0.0.0.0',
  6256,
  'Master Server'
);

INSERT INTO `server_list` (
  `ip`,
  `port`,
  `name`
) VALUES (
  '0.0.0.0',
  6256,
  'Server 1'
);
