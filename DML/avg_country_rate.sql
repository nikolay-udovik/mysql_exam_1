--
-- show statistics for by country
--
DROP VIEW IF EXISTS statistic_by_country;
CREATE VIEW statistic_by_country AS (
SELECT 
	c.country_name,
	COUNT(c.country_name) AS Players,
	FLOOR(AVG(daily_rate)) AS Daily_AVG, 
	FLOOR(AVG(ur.rapid_rate)) AS Rapid_AVG, 
	FLOOR(AVG(blitz_rate)) AS Blitz_AVG, 
	FLOOR(AVG(bullet_rate)) AS Bullet_AVG
FROM user_rate ur 
INNER JOIN user_info ui ON (
	ui.fk_user_id = ur.pk_fk_user_id
)
LEFT JOIN countries c ON (
	fk_location = c.pk_id
)
GROUP BY c.country_name
ORDER BY Players DESC
)
;
