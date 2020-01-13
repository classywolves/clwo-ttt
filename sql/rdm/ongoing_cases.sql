CREATE OR REPLACE VIEW `ongoing_cases` AS
SELECT
    `reports`.`death_index`,
    `handles`.`admin_id`
FROM `reports`
    LEFT JOIN `handles` ON `reports`.`death_index` = `handles`.`death_index`
WHERE `handles`.`verdict` IS NULL
GROUP BY `reports`.`death_index`;