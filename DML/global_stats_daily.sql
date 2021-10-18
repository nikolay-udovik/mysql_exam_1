--
-- show 'daily chess' statistics for all users
--
DROP VIEW IF EXISTS daily_chess_statistics;
CREATE VIEW daily_chess_statistics AS (
	SELECT
		ui.fk_user_id AS UserID,
		CONCAT_WS(' ', ui.user_firstname, ui.user_lastname) AS Player, 
		c.country_name AS Country,
		ur.daily_rate AS Rating,
		dcs.Won,
		dcs.Lost
	FROM user_info ui 
	LEFT JOIN countries c ON (
		ui.fk_location = c.pk_id
	)
	INNER JOIN user_rate ur ON (
		ur.pk_fk_user_id = ui.pk_id 
	)
	INNER JOIN (
		SELECT 
			Player,
			SUM(wins) AS Won,
			SUM(lost) AS lost
		FROM 
		(
			(
				SELECT fk_player_1 AS Player, 
				SUM(p1_score) AS wins,
				SUM(p2_score) AS lost
				FROM game_sessions
				WHERE rated IS TRUE 
				AND	is_finished IS TRUE
				AND fk_game_type IN (9, 10, 11, 12, 13) 
				GROUP BY fk_player_1 
			) 
			UNION 
			(
				SELECT fk_player_2 AS Player, 
				SUM(p2_score) AS wins,
				SUM(p1_score) AS lost 
				FROM game_sessions
				WHERE rated IS TRUE 
				AND	is_finished IS TRUE
				AND fk_game_type IN (9, 10, 11, 12, 13) 
				GROUP BY fk_player_2 
			)
		) AS daily_chess_statistics
		GROUP BY Player
	) AS dcs  ON (
		dcs.Player = ui.pk_id 
	)
	ORDER BY Rating DESC
)
;
