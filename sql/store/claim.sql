CREATE TABLE IF NOT EXISTS `store_claim`
(
    `account_id` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`account_id`)
)
ENGINE = InnoDB;

SELECT `account_id` FROM `store_claim` WHERE `account_id` = '%d';

INSERT INTO `store_claim` (`account_id`) VALUES ('%d');

DELETE FROM `store_claim` WHERE `account_id` = '%d';
