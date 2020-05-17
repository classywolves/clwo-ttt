CREATE TABLE IF NOT EXISTS `ttt_store`.`store_players`
(
	`account_id` INT UNSIGNED NOT NULL,
	`credits` INT UNSIGNED NOT NULL,  
	PRIMARY KEY (`account_id`)
)
ENGINE = InnoDB;

SELECT `credits` FROM `store_players` WHERE `account_id` = '%d';

INSERT INTO `store_players` (`account_id`, `credits`) VALUES ('%d', '%d');

UPDATE `store_players` SET `credits` = '%d' WHERE `account_id` = '%d';
