CREATE TABLE `ttt_db`.`skills` 
(
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`auth_id` VARCHAR(32) NOT NULL,
	`level` INT UNSIGNED NOT NULL,
	`experience` INT UNSIGNED NOT NULL,
	`points` INT UNSIGNED NOT NULL,
	`skill_0` TINYINT UNSIGNED NOT NULL,
	`skill_1` TINYINT UNSIGNED NOT NULL,
	`skill_2` TINYINT UNSIGNED NOT NULL,
	`skill_3` TINYINT UNSIGNED NOT NULL,
	`skill_4` TINYINT UNSIGNED NOT NULL,
	`skill_5` TINYINT UNSIGNED NOT NULL,
	`skill_6` TINYINT UNSIGNED NOT NULL,
	`skill_7` TINYINT UNSIGNED NOT NULL,
	`skill_8` TINYINT UNSIGNED NOT NULL,
	`skill_9` TINYINT UNSIGNED NOT NULL,
	`skill_10` TINYINT UNSIGNED NOT NULL,
	`skill_11` TINYINT UNSIGNED NOT NULL,
	`skill_12` TINYINT UNSIGNED NOT NULL,
	`skill_13` TINYINT UNSIGNED NOT NULL,
	`skill_14` TINYINT UNSIGNED NOT NULL,
	`skill_15` TINYINT UNSIGNED NOT NULL,
	`skill_16` TINYINT UNSIGNED NOT NULL,
	`skill_17` TINYINT UNSIGNED NOT NULL,
	`skill_18` TINYINT UNSIGNED NOT NULL,
	`skill_19` TINYINT UNSIGNED NOT NULL,
	`skill_20` TINYINT UNSIGNED NOT NULL,
	`skill_21` TINYINT UNSIGNED NOT NULL,
	`skill_22` TINYINT UNSIGNED NOT NULL,
	`skill_23` TINYINT UNSIGNED NOT NULL,
	`skill_24` TINYINT UNSIGNED NOT NULL,
	`skill_25` TINYINT UNSIGNED NOT NULL,
	`skill_26` TINYINT UNSIGNED NOT NULL,
	`skill_27` TINYINT UNSIGNED NOT NULL,
	`skill_28` TINYINT UNSIGNED NOT NULL,
	`skill_29` TINYINT UNSIGNED NOT NULL,
	`skill_30` TINYINT UNSIGNED NOT NULL,
	`skill_31` TINYINT UNSIGNED NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE `auth_index` (`auth_id`)
)
ENGINE = InnoDB;

SELECT `level`, `experience`, `points`, `skill_0`, `skill_1`, `skill_2`, `skill_3`, `skill_4`, `skill_5`, `skill_6`, `skill_7`, `skill_8`, `skill_9`, `skill_10`, `skill_11`, `skill_12`, `skill_13`, `skill_14`, `skill_15`, `skill_16`, `skill_17`, `skill_18`, `skill_19`, `skill_20`, `skill_21`, `skill_22`, `skill_23`, `skill_24`, `skill_25`, `skill_26`, `skill_27`, `skill_28`, `skill_29`, `skill_30`, `skill_31` FROM `skills` WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;

INSERT INTO `skills_data` (`id`, `auth_id`, `level`, `experience`, `points`, `skill_0`, `skill_1`, `skill_2`, `skill_3`, `skill_4`, `skill_5`, `skill_6`, `skill_7`, `skill_8`, `skill_9`, `skill_10`, `skill_11`, `skill_12`, `skill_13`, `skill_14`, `skill_15`, `skill_16`, `skill_17`, `skill_18`, `skill_19`, `skill_20`, `skill_21`, `skill_22`, `skill_23`, `skill_24`, `skill_25`, `skill_26`, `skill_27`, `skill_28`, `skill_29`, `skill_30`, `skill_31`) VALUES (NULL, '%s', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0');

UPDATE `skills` SET `level` = '%d', `experience` = '%d', `points` = '%d', `skill_0` = '%d', `skill_1` = '%d', `skill_2` = '%d', `skill_3` = '%d', `skill_4` = '%d', `skill_5` = '%d', `skill_6` = '%d', `skill_7` = '%d', `skill_8` = '%d', `skill_9` = '%d', `skill_10` = '%d', `skill_11` = '%d', `skill_12` = '%d', `skill_13` = '%d', `skill_14` = '%d', `skill_15` = '%d', `skill_16` = '%d', `skill_17` = '%d', `skill_18` = '%d', `skill_19` = '%d', `skill_20` = '%d', `skill_21` = '%d', `skill_22` = '%d', `skill_23` = '%d', `skill_24` = '%d', `skill_25` = '%d', `skill_26` = '%d', `skill_27` = '%d', `skill_28` = '%d', `skill_29` = '%d', `skill_30` = '%d', `skill_31` = '%d' WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;

