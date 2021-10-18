--
-- moving completed games to archive
--
DELIMITER //
DROP PROCEDURE IF EXISTS mv_completed_games_to_archive//
CREATE PROCEDURE mv_completed_games_to_archive()
BEGIN
	
	DECLARE i_game_id BIGINT;
 	DECLARE is_end INT DEFAULT 0;
	DECLARE iter_completed_games CURSOR FOR SELECT game_id FROM moves WHERE game_result != 0;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET is_end = 1;
	OPEN iter_completed_games;
	iter_games : LOOP
		FETCH iter_completed_games INTO i_game_id;
		IF is_end THEN LEAVE iter_games;
		END IF;
	
		INSERT INTO game_archive (event, game_id, white, black, game_result, game_log)
		SELECT
			gs.pk_id AS Event, -- game session id
			g.pk_id AS Site,   -- game id
			IF (s.plays_white = 1, gs.fk_player_1, gs.fk_player_2) AS White,
			IF (s.plays_white = 2, gs.fk_player_1, gs.fk_player_2) AS Black,
			CASE 
				WHEN s.game_result = 1 THEN CONCAT('Win ', gs.fk_player_1)
				WHEN s.game_result = 2 THEN CONCAT('Win ', gs.fk_player_2)
				WHEN s.game_result = 3 THEN 'Draw'
			END AS game_result,
			(
				SELECT 
					GROUP_CONCAT(CONCAT_WS('.', move_number, move) SEPARATOR ' ') 
				FROM (
					SELECT 
						move_number, 
						CASE 
							WHEN p1_move IS NULL THEN p2_move 
							ELSE P1_move
						END AS move	
					FROM moves
					WHERE game_id = i_game_id
				) AS move_log
		) AS game_log
		FROM game_sessions gs
		INNER JOIN games g ON gs.pk_id = g.fk_session_id
		INNER JOIN moves s ON s.game_id = g.pk_id 
		WHERE 
			g.pk_id = i_game_id
			AND s.game_result != 0;
		DELETE FROM moves WHERE game_id = i_game_id;
	END LOOP iter_games;
	CLOSE iter_completed_games;
END//


DROP EVENT IF EXISTS arhive_completed_games //
CREATE DEFINER=`root`@`%` 
EVENT `arhive_completed_games` 
ON SCHEDULE EVERY 2 MINUTE STARTS NOW()
ON COMPLETION NOT PRESERVE ENABLE
DO 
BEGIN
 	SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = 'moving completed games started';
	CALL mv_completed_games_to_archive();
	SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = 'moving completed games finished';
END//
DELIMITER ;
