-- Ouro Society Tables

-- Job Grades and Salaries
CREATE TABLE IF NOT EXISTS `ouro_society` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` varchar(50) NOT NULL,
  `jobgrade` int(11) NOT NULL,
  `salary` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `job_grade` (`job`, `jobgrade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Job Ledgers (Society Money)
CREATE TABLE IF NOT EXISTS `ouro_society_ledger` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` varchar(50) NOT NULL,
  `ledger` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Job Storage Containers
CREATE TABLE IF NOT EXISTS `ouro_container` (
  `id` int(11) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `items` longtext NOT NULL DEFAULT '[]',
  `max_slots` int(11) DEFAULT 50,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Bills System
CREATE TABLE IF NOT EXISTS `ouro_bills` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` varchar(50) DEFAULT NULL,
  `playername` varchar(100) DEFAULT NULL,
  `identifier` varchar(50) DEFAULT NULL,
  `charidentifier` int(11) DEFAULT NULL,
  `issuer` varchar(100) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `charidentifier` (`charidentifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Player Jobs (MultiJob System)
CREATE TABLE IF NOT EXISTS `ouro_player_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `charidentifier` int(11) NOT NULL,
  `job` varchar(50) NOT NULL,
  `grade` int(11) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `charidentifier` (`charidentifier`),
  KEY `job_active` (`job`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Player SubJobs
CREATE TABLE IF NOT EXISTS `ouro_player_subjobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `charidentifier` int(11) NOT NULL,
  `main_job` varchar(50) NOT NULL,
  `subjob` varchar(50) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `charidentifier` (`charidentifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Duty Status
CREATE TABLE IF NOT EXISTS `ouro_duty_status` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `charidentifier` int(11) NOT NULL,
  `job` varchar(50) NOT NULL,
  `on_duty` tinyint(1) DEFAULT 0,
  `last_update` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `char_job` (`charidentifier`, `job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Example data for default containers
INSERT INTO `ouro_container` (`id`, `name`, `items`, `max_slots`) VALUES
(1, 'Sheriff Storage', '[]', 100),
(2, 'Medical Storage', '[]', 100),
(10, 'Valentine General Store', '[]', 75),
(11, 'Valentine Stables', '[]', 75),
(12, 'Mining Storage', '[]', 50)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- Example data for default ledgers
INSERT INTO `ouro_society_ledger` (`job`, `ledger`) VALUES
('sheriff', 500),
('doctor', 300),
('valgeneral', 0),
('valstables', 0),
('miner', 0)
ON DUPLICATE KEY UPDATE `job` = VALUES(`job`);

-- Example data for default job grades
INSERT INTO `ouro_society` (`job`, `jobgrade`, `salary`) VALUES
-- Sheriff
('sheriff', 0, 10),
('sheriff', 1, 20),
('sheriff', 2, 30),
('sheriff', 3, 40),
('sheriff', 4, 50),
('sheriff', 5, 60),
('sheriff', 6, 75),
-- Doctor
('doctor', 0, 15),
('doctor', 1, 25),
('doctor', 2, 40),
('doctor', 3, 55),
('doctor', 4, 65),
('doctor', 5, 80),
-- Business Examples
('valgeneral', 0, 0),
('valgeneral', 1, 0),
('valgeneral', 2, 0),
('valgeneral', 3, 0),
('valstables', 0, 0),
('valstables', 1, 0),
('valstables', 2, 0),
('valstables', 3, 0),
('miner', 0, 0),
('miner', 1, 0),
('miner', 2, 0),
('miner', 3, 0)
ON DUPLICATE KEY UPDATE `salary` = VALUES(`salary`);

