-- ============================================
-- OURO SOCIETY - CLAN SYSTEM
-- ============================================
-- Run this AFTER society.sql

-- ============================================
-- DROP OLD CLAN TABLES (if they exist)
-- ============================================
DROP TABLE IF EXISTS `ouro_player_clans`;
DROP TABLE IF EXISTS `ouro_clan_storage`;
DROP TABLE IF EXISTS `ouro_clan_members`;
DROP TABLE IF EXISTS `ouro_clan_ledger`;
DROP TABLE IF EXISTS `ouro_clans`;

-- ============================================
-- CREATE NEW CLAN TABLES
-- ============================================

-- Clan Grades and Salaries (like ouro_society for jobs)
CREATE TABLE `ouro_clans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `clan` varchar(50) NOT NULL,
  `clangrade` int(11) NOT NULL,
  `salary` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `clan_grade` (`clan`, `clangrade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Clan Ledgers (Clan Bank Accounts)
CREATE TABLE `ouro_clan_ledger` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `clan` varchar(50) NOT NULL,
  `ledger` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `clan` (`clan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Player Clans (Multi-clan system, max 2 per player)
CREATE TABLE `ouro_player_clans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `charidentifier` int(11) NOT NULL,
  `clan` varchar(50) NOT NULL,
  `grade` int(11) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 0,
  `joined_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `charidentifier` (`charidentifier`),
  KEY `clan` (`clan`),
  KEY `clan_active` (`clan`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- SEED DATA FOR CLANS
-- ============================================

-- Red Chariot Clan
INSERT INTO `ouro_clan_ledger` (`clan`, `ledger`) VALUES 
('redchariot', 1000);

INSERT INTO `ouro_clans` (`clan`, `clangrade`, `salary`) VALUES
('redchariot', 0, 0),
('redchariot', 1, 10),
('redchariot', 2, 20),
('redchariot', 3, 30),
('redchariot', 4, 40),
('redchariot', 5, 50);

INSERT INTO `ouro_container` (`id`, `name`, `items`, `max_slots`) VALUES 
(50, 'Red Chariot Storage', '[]', 150)
ON DUPLICATE KEY UPDATE `name` = 'Red Chariot Storage';

-- Blue Cartsmen Clan
INSERT INTO `ouro_clan_ledger` (`clan`, `ledger`) VALUES 
('bluecartsmen', 1000);

INSERT INTO `ouro_clans` (`clan`, `clangrade`, `salary`) VALUES
('bluecartsmen', 0, 0),
('bluecartsmen', 1, 10),
('bluecartsmen', 2, 20),
('bluecartsmen', 3, 30),
('bluecartsmen', 4, 40),
('bluecartsmen', 5, 50);

INSERT INTO `ouro_container` (`id`, `name`, `items`, `max_slots`) VALUES 
(51, 'Blue Cartsmen Storage', '[]', 150)
ON DUPLICATE KEY UPDATE `name` = 'Blue Cartsmen Storage';

-- ============================================
-- NOTES
-- ============================================
-- To manually add a player to a clan:
-- INSERT INTO `ouro_player_clans` (`identifier`, `charidentifier`, `clan`, `grade`, `is_active`) 
-- VALUES ('steam:xxxxx', 1, 'redchariot', 5, 1);
--
-- Or use the server event:
-- TriggerServerEvent('ouro_society:server:SaveClan', 'redchariot', 5)
