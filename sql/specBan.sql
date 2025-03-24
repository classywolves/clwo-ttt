CREATE TABLE `ttt_db`.`spec_bans` 
(
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`auth_id` VARCHAR(32) NOT NULL,
    `name` VARCHAR(64),
    `created` INT(11) NOT NULL,
    `ends` INT(11) NOT NULL,
    `length` INT(10) NOT NULL,
    `reason` TEXT NOT NULL,
    `staff_auth` VARCHAR(32) NOT NULL,
    `staff_name` VARCHAR(64) NOT NULL,
    `removed_by` VARCHAR(32) NULL,
    `remove_type` VARCHAR(3) NULL,
    `removed_on` INT(11) NULL,
    `ureason` TEXT NULL,
	PRIMARY KEY (`id`),
	UNIQUE `ban_index` (`auth_id`, `created`)
)
ENGINE = InnoDB;

-- Inserts a new ban.
INSERT INTO `spec_bans` (`auth_id`, `name`, `created`, `ends`, `length`, `reason`, `staff_auth`, `staff_name`) VALUES ('%s', '%s', '%d', '%d', '%d', '%s', '%s', '%s');

-- Select a players latest valid spec ban if one exists.
SELECT `ends` FROM `spec_bans` WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' AND `ends` > '%d' AND `remove_type` IS NULL LIMIT 1;

-- Expire bans
UPDATE `spec_bans` SET `remove_type` = 'E', `removed_on` = '%d', `ureason` = 'Ban Expired' WHERE `ends` <= '%d' AND `remove_type` IS NULL;

-- Un spec ban
UPDATE `spec_bans` SET `removed_by` = '%s', `remove_type` = 'U', `removed_on` = '%s', `ureason` = '%s' WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' AND `ends` <= '%d' LIMIT 1;