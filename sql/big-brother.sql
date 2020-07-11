CREATE TABLE IF NOT EXISTS `big_brother_chat`
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

CREATE TABLE IF NOT EXISTS `big_brother_msg`
(
    `id` INT UNSIGNED AUTO_INCREMENT,
    `time` INT UNSIGNED NOT NULL,
    `sender_id` INT UNSIGNED NOT NULL,
    `receiver_id` INT UNSIGNED NOT NULL,
    `message` VARCHAR(256),
    PRIMARY KEY(`id`),
    INDEX(`time`),
    INDEX(`sender_id`),
    INDEX(`receiver_id`)
)
ENGINE = InnoDB;

INSERT INTO `big_brother_chat` (`time`, `account_id`, `message`) VALUES (UTC_TIMESTAMP(), '%d', '%s');

INSERT INTO `big_brother_msg` (`time`, `account_id`, `receiver_id`, `message`) VALUES (UTC_TIMESTAMP(), '%d', '%d', '%s');

