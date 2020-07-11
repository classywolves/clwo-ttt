CREATE TABLE IF NOT EXISTS `big_brother`
(
    `id` INT UNSIGNED AUTO_INCREMENT,
    `time` INT UNSIGNED NOT NULL,
    `account_id` INT UNSIGNED NOT NULL,
    `message` VARCHAR(256),
    PRIMARY KEY(`id`),
    INDEX(`time`),
    INDEX(`account_id`)
)
ENGINE = InnoDB;

INSERT INTO `big_brother` (`time`, `account_id`, `message`) VALUES (UTC_TIMESTAMP(), '%d', '%s');
