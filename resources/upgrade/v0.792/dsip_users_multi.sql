-- Multi-User Support Migration (v0.792)
-- Creates dsip_users, dsip_groups, dsip_user_groups tables
-- Migrates data from dsip_user and auto-creates admin from dsip_settings

-- ============================================================
-- 1. Create new tables
-- ============================================================

CREATE TABLE IF NOT EXISTS dsip_users (
  username VARCHAR(255) NOT NULL,
  password VARBINARY(256) COLLATE 'binary' NULL,
  api_token VARCHAR(255) NOT NULL,
  auth_type ENUM('local','ldap') NOT NULL DEFAULT 'local',
  PRIMARY KEY (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS dsip_groups (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  description VARCHAR(255) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS dsip_user_groups (
  username VARCHAR(255) NOT NULL,
  group_id INT NOT NULL,
  PRIMARY KEY (username, group_id),
  FOREIGN KEY (username) REFERENCES dsip_users(username) ON DELETE CASCADE,
  FOREIGN KEY (group_id) REFERENCES dsip_groups(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ============================================================
-- 2. Seed default groups
-- ============================================================

INSERT IGNORE INTO dsip_groups (name, description) VALUES
  ('dsip_admin', 'Full read/write access to all resources'),
  ('dsip_engineer', 'Read on Dashboard/Settings; read/write on CGs/EGs/Domains/Inbound/Outbound'),
  ('dsip_guest', 'Read-only access to Dashboard/CGs/EGs/Domains/Inbound/Outbound');

-- ============================================================
-- 3. Migrate existing dsip_user data to dsip_users
-- ============================================================

-- Deprecated dsip_user.password was stored AES-CTR encrypted (not a
-- Credentials.hashCreds() hash), so it cannot be migrated as-is. Preserve the
-- API token for continuity and leave the password NULL; the user will need a
-- password reset via the admin. Migratable passwords are handled in section 4.
INSERT IGNORE INTO dsip_users (username, password, api_token, auth_type)
SELECT
  username,
  NULL,
  IFNULL(token, ''),
  'local'
FROM dsip_user;

-- Assign migrated legacy users the dsip_guest role by default
-- (the settings-based admin is assigned dsip_admin in section 4)
INSERT IGNORE INTO dsip_user_groups (username, group_id)
SELECT
  u.username,
  g.id
FROM dsip_users u
CROSS JOIN dsip_groups g
WHERE g.name = 'dsip_guest';

-- ============================================================
-- 4. Auto-create admin user from dsip_settings if not exists
-- ============================================================

INSERT IGNORE INTO dsip_users (username, password, api_token, auth_type)
SELECT
  DSIP_USERNAME,
  DSIP_PASSWORD,
  '',
  'local'
FROM dsip_settings;

-- Assign dsip_admin group to the admin user
INSERT IGNORE INTO dsip_user_groups (username, group_id)
SELECT
  s.DSIP_USERNAME,
  g.id
FROM dsip_settings s
CROSS JOIN dsip_groups g
WHERE g.name = 'dsip_admin'
  AND NOT EXISTS (
    SELECT 1 FROM dsip_user_groups ug
    JOIN dsip_users u ON u.username = ug.username
    WHERE u.username = s.DSIP_USERNAME AND ug.group_id = g.id
  );

-- ============================================================
-- 5. Drop old dsip_user table (after migration is verified)
-- ============================================================

-- Uncomment after verifying migration:
-- DROP TABLE IF EXISTS dsip_user;
