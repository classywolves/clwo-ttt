CREATE TABLE IF NOT EXISTS `jumprecords_lj`
(
    `account_id` INT UNSIGNED NOT NULL,
    `time`       INT UNSIGNED NOT NULL,
    `distance`   FLOAT NOT NULL,
    PRIMARY KEY (`account_id`),
    INDEX (`time`),
    INDEX (`distance`)
)
ENGINE = InnoDB;

CREATE OR REPLACE VIEW `v_jumprecords_lj` AS
SELECT
    `jumprecords_lj`.`account_id`,
    `player_info`   .`name`,
    `jumprecords_lj`.`time`,
    `jumprecords_lj`.`distance`
FROM `jumprecords_lj`
    LEFT JOIN `player_info` ON `jumprecords_lj`.`account_id` = `player_info`.`account_id`
GROUP BY `jumprecords_lj`.`account_id`;

-- select top 10 LJ
SELECT `name`, `distance` FROM `v_jumprecords_lj` ORDER BY `distance` DESC LIMIT 10;

-- select personal best LJ
SELECT `distance` FROM `jumprecords_lj` WHERE `account_id` = '%d' LIMIT 1;

-- insert new LJ
INSERT INTO `jumprecords_lj` (`account_id`, `time`, `distance`) VALUES ('%d', '%d', '%f') ON DUPLICATE KEY UPDATE `time`='%d', `distance`='%f';
