CREATE TABLE IF NOT EXISTS `bb_chat`
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

CREATE TABLE IF NOT EXISTS `bb_msg`
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

INSERT INTO `bb_chat` (`time`, `account_id`, `message`) VALUES (UNIX_TIMESTAMP(), '%d', '%s');

INSERT INTO `bb_msg` (`time`, `account_id`, `receiver_id`, `message`) VALUES (UNIX_TIMESTAMP(), '%d', '%d', '%s');

CREATE OR REPLACE VIEW `v_bb_chat` AS
SELECT
    `bb_chat`.`id`,
    `bb_chat`.`time`,
    `bb_chat`.`account_id`,
    `player_info`.`name`,
    `bb_chat`.`message`
FROM `bb_chat`
    LEFT JOIN `player_info` ON `bb_chat`.`account_id` = `player_info`.`account_id`
GROUP BY `bb_chat`.`id`;

CREATE OR REPLACE VIEW `v_bb_msg` AS
SELECT
    `bb_msg`.`id`,
    `bb_msg`.`time`,
    `bb_msg`.`sender_id`,
    `sender_info`.`name` as `sender_name`,
    `bb_msg`.`receiver_id`,
    `receiver_info`.`name` as `receiver_name`,
    `bb_msg`.`message`
FROM `bb_msg`
    LEFT JOIN `player_info` `sender_info` ON `bb_msg`.`sender_id` = `sender_info`.`account_id`
    LEFT JOIN `player_info` `receiver_info` ON `bb_msg`.`receiver_id` = `receiver_info`.`account_id`
GROUP BY `bb_msg`.`id`;
