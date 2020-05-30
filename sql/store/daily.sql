CREATE TABLE IF NOT EXISTS `store_daily`
(
    `account_id` INT UNSIGNED NOT NULL,
    `last_day` INT UNSIGNED DEFAULT '0' NOT NULL,
    `cons_days` INT UNSIGNED DEFAULT '0' NOT NULL,
    PRIMARY KEY (`account_id`),
    INDEX (`last_day`)
)
ENGINE = InnoDB;

INSERT INTO `store_daily` (`account_id`, `last_day`, `cons_days`) VALUES ('%d', '%d', '0');

SELECT `last_day`, `cons_days` FROM `store_daily` WHERE `account_id` = '%d' LIMIT 1;

UPDATE `store_daily` SET `last_day` = '%d', `cons_days` = '%d'  WHERE `account_id` = '%d' LIMIT 1;