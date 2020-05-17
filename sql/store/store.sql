CREATE TABLE IF NOT EXISTS `ttt_store`.`store_items` 
(
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`account_id` INT UNSIGNED NOT NULL,
	`item_id` VARCHAR(16) NOT NULL,
    `quantity` INT UNSIGNED NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE `unique_item_entry` (`account_id`, `item_id`)
)
ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `ttt_store`.`store_skills` 
(
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`account_id` INT UNSIGNED NOT NULL,
	`skill_id` VARCHAR(16) NOT NULL,
    `level` INT UNSIGNED NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE `unique_skill_entry` (`account_id`, `skill_id`)
)
ENGINE = InnoDB;

SELECT `item_id`, `quantity` FROM `store_items` WHERE `account_id` = '%d';

SELECT `skill_id`, `level` FROM `store_skills` WHERE `account_id` = '%d';

INSERT INTO `store_skills` (`account_id`, `skill_id`, `level`) VALUES ('%d', '%s', '%d') ON DUPLICATE KEY UPDATE `level` = '%d';
