--
-- Generate moves. md5 will emulate move strings like 'Nf3 Nc6'
--
TRUNCATE moves; 


DELIMITER //
DROP PROCEDURE IF EXISTS fill_up_moves_m //
CREATE PROCEDURE fill_up_moves_m ()
BEGIN
	-- first loop vars
	DECLARE is_end INT DEFAULT 0;
	DECLARE game_id BIGINT;

	DECLARE l_game_id CURSOR FOR 
		SELECT pk_id FROM games;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET is_end = 1;

	OPEN l_game_id;
	for_game_ids : LOOP
		FETCH l_game_id INTO game_id;
		IF is_end THEN LEAVE for_game_ids;
		END IF;
	
		-- second loop
		CALL fill_up_moves_h(game_id);
	END LOOP for_game_ids;
	CLOSE l_game_id;
END //

DROP PROCEDURE IF EXISTS fill_up_moves_h //
CREATE PROCEDURE fill_up_moves_h (IN game_id BIGINT)
BEGIN
	DECLARE move_number INT DEFAULT 1;
	DECLARE plays_white INT DEFAULT 0;
	DECLARE i INT DEFAULT FLOOR(1 + 25 * RAND());  -- random amount of moves per game
 	-- move log. let's imagine it looks like 'Nf3 Nc6' :)
	DECLARE p1_move VARCHAR(20) DEFAULT NULL;
	DECLARE p2_move VARCHAR(20) DEFAULT NULL;
	-- 1 for p1 win, 2 for p2 win, 3 for draw
	DECLARE game_result TINYINT;
	-- decide who plays white
	SET plays_white = FLOOR(1 + 2 * RAND());

	WHILE i > 0 DO
		-- white begins
		IF MOD(move_number, 2) <> 0 THEN 
			SET p1_move =  SUBSTRING(md5(rand()), 1, 7);
			SET p2_move = NULL;
		ELSEIF MOD(move_number, 2) = 0 THEN
			SET p1_move = NULL;
			SET p2_move =  SUBSTRING(md5(rand()), 1, 7);
		END IF;
		-- random winner at the last move
		IF i = 1 THEN 
			SET game_result = FLOOR(0 + 3 * RAND());
		ELSE
			SET game_result = 0; -- game in progress
		END IF;
		
		-- insert 
		INSERT INTO moves (`game_id`, `plays_white`, `move_number`, `p1_move`, `p2_move`, `game_result`) 
		VALUES (game_id, plays_white, move_number, p1_move, p2_move, game_result);
	
		-- update counters
		SET move_number = move_number + 1;
		SET i = i - 1;
	END WHILE;
END //
DELIMITER ;


CALL fill_up_moves_m();