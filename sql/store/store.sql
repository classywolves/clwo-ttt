CREATE TABLE IF NOT EXISTS `store_items` 
(
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`account_id` INT UNSIGNED NOT NULL,
	`item_id` VARCHAR(16) NOT NULL,
    `quantity` INT UNSIGNED NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE `unique_item_entry` (`account_id`, `item_id`)
)
ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `store_skills` 
(
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`account_id` INT UNSIGNED NOT NULL,
	`skill_id` VARCHAR(16) NOT NULL,
    `level` INT UNSIGNED NOT NULL,
	`enabled` BOOLEAN NOT NULL DEFAULT TRUE,
	PRIMARY KEY (`id`),
	UNIQUE `unique_skill_entry` (`account_id`, `skill_id`)
)
ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `store_upgrades` 
(
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`account_id` INT UNSIGNED NOT NULL,
	`upg_id` VARCHAR(16) NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE `unique_upg_entry` (`account_id`, `upg_id`)
)
ENGINE = InnoDB;

-- SKILLS

SELECT `skill_id`, `level`, `enabled` FROM `store_skills` WHERE `account_id` = '%d';

INSERT INTO `store_skills` (`account_id`, `skill_id`, `level`) VALUES ('%d', '%s', '%d') ON DUPLICATE KEY UPDATE `level` = '%d';

UPDATE `store_skills` SET `enabled` = %s WHERE `account_id` = '%d' AND `skill_id` = '%d';

-- UPGRADES

SELECT `upg_id` FROM `store_upgrades` WHERE `account_id` = '%d';

INSERT INTO `store_upgrades` (`account_id`, `upg_id`) VALUES ('%d', '%s');
