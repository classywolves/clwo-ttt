CREATE TABLE IF NOT EXISTS `ttt_db`.`player_info` 
(
	`account_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(64) NOT NULL,
	`auth_id` VARCHAR(32) NOT NULL,
    `community_id` VARCHAR(64) NOT NULL,
	PRIMARY KEY (`account_id`),
	UNIQUE `auth_index` (`auth_id`),
    UNIQUE `community_index` (`community_id`)
)
ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `ttt_db`.`player_names` 
(
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(64) NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE `account_name` (`account_id`, `name`)
)
ENGINE = InnoDB;

INSERT INTO `player_info` (`account_id`, `name`, `auth_id`, `community_id`) VALUES ('%d', '%s', '%s', '%s') ON DUPLICATE KEY UPDATE `name` = '%s';

INSERT INTO `player_names` (`account_id`, `name`) VALUES ('%d', '%s') ON DUPLICATE KEY UPDATE `id`=`id`;
