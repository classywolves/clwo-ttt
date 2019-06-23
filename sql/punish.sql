CREATE TABLE IF NOT EXISTS `ttt_db`.`punish`
(
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`auth_id` VARCHAR(32) NOT NULL,
	`name` VARCHAR(64) NOT NULL,
	`time` INT(11) NOT NULL,
	`reason` VARCHAR(128) NOT NULL,
	`type` INT(11) NOT NULL,
    `auth_admin` VARCHAR(32) NOT NULL,
    `name_admin` VARCHAR(32) NOT NULL,
    PRIMARY KEY (`id`),
	UNIQUE `authtime_index` (`auth_id`, `time`)
)
ENGINE = InnoDB;

INSERT INTO `punish` (`id`, `auth_id`, `name`, `time`, `reason`, `type`, `auth_admin`, `name_admin`) VALUES (NULL, '%s', '%s', '%d', '%s', '%i', '%s', '%s');

SELECT SUM (CASE WHEN `type` = 0 THEN 1 ELSE 0 END), SUM (CASE WHEN `type` = 1 THEN 1 ELSE 0 END), SUM (CASE WHEN `type` = 1 THEN 1 ELSE 0 END) FROM `punish` WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' AND `time` > '%i' - '259200';