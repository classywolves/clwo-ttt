CREATE TABLE IF NOT EXISTS `store_daily`
(
	`account_id` INT UNSIGNED NOT NULL,
	`last_time` INT UNSIGNED NOT NULL,
	PRIMARY KEY (`account_id`),
	INDEX (`last_time`)
)
ENGINE = InnoDB;

INSERT INTO `store_daily` (`account_id`, `last_time`) VALUES ('%d', '%d') ON DUPLICATE KEY UPDATE `last_time` = '%d';

SELECT `last_time` FROM `store_daily` WHERE `account_id` = '%d' ORDER BY `last_time` DESC LIMIT 1;