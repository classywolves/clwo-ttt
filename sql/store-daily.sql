CREATE TABLE IF NOT EXISTS `store_daily`
(
	`account_id` INT UNSIGNED NOT NULL,
	`last_time` INT UNSIGNED NOT NULL,
	`cons_days` INT UNSIGNED NOT NULL,
	PRIMARY KEY (`account_id`),
	INDEX (`last_time`)
)
ENGINE = InnoDB;

INSERT INTO `store_daily` (`account_id`, `last_time`, `cons_days`) VALUES ('%d', '%d', '0');

SELECT `last_time`, `cons_days` FROM `store_daily` WHERE `account_id` = '%d' LIMIT 1;

UPDATE `store_daily` SET `last_time` = '%d', `cons_days` = '%d'  WHERE `account_id` = '%d' LIMIT 1;