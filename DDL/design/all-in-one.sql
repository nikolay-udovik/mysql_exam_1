--
-- Definition of all tables
--

START TRANSACTION;
SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS chess;
CREATE DATABASE chess;
USE chess;



DROP TABLE IF EXISTS countries;
CREATE TABLE countries (
	pk_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	phone_code INT UNSIGNED NOT NULL,
	country_code CHAR(2) NOT NULL,
	country_name VARCHAR(80) NOT NULL,
	PRIMARY KEY (pk_id),
	KEY key_country_name(country_name)
) COMMENT "Countries, phone/country codes";



DROP TABLE IF EXISTS user_accounts;
CREATE TABLE user_accounts (
	pk_id SERIAL PRIMARY KEY,
	user_uuid CHAR(36) UNIQUE NOT NULL UNIQUE COMMENT 'displayed to the user',
	user_email VARCHAR(100) NOT NULL UNIQUE,
	user_pass VARCHAR(255) NOT NULL COMMENT 'secure salted password hash',
	user_registered DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	user_account_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	KEY key_user_email (user_email),
	CONSTRAINT chk_user_uuid CHECK (IS_UUID(user_uuid)) -- verify that value is uuid
) ENGINE=InnoDB COMMENT '1st schema: rarely changed info specified during registration';



DROP TABLE IF EXISTS user_info;
CREATE TABLE user_info (
	pk_id SERIAL PRIMARY KEY COMMENT 'ro id',
	fk_user_id BIGINT UNSIGNED NOT NULL,
	user_firstname VARCHAR(50),
	user_lastname VARCHAR(50),
	fk_location INT UNSIGNED NOT NULL,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	FOREIGN KEY (fk_user_id) REFERENCES user_accounts(pk_id),
	FOREIGN KEY (fk_location) 
		REFERENCES countries(pk_id) 
		ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT 'user information';



-- 
-- user_rate: each user has a single reccord that describes the current rate status.
-- 
DROP TABLE IF exists user_rate;
CREATE TABLE IF NOT EXISTS user_rate(
	pk_fk_user_id BIGINT UNSIGNED NOT NULL,
	rapid_rate SMALLINT UNSIGNED NOT NULL DEFAULT 800,
	bullet_rate SMALLINT UNSIGNED NOT NULL DEFAULT 800,
	daily_rate SMALLINT UNSIGNED NOT NULL DEFAULT 800,
	blitz_rate SMALLINT UNSIGNED NOT NULL DEFAULT 800,
	PRIMARY KEY (pk_fk_user_id),
	FOREIGN KEY (pk_fk_user_id) REFERENCES user_accounts(pk_id)
) ENGINE=InnoDB;



DROP TABLE IF EXISTS game_types;
CREATE TABLE game_types(
	pk_id SERIAL PRIMARY KEY,
	name VARCHAR(30) NOT NULL,
	time_limit VARCHAR(30) COMMENT 'Describes time limit for the game', -- INT does not fit.
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;



DROP TABLE IF EXISTS game_sessions;
CREATE TABLE game_sessions (
	pk_id SERIAL PRIMARY KEY COMMENT 'just row id',
	session_uuid CHAR(36) UNIQUE NOT NULL UNIQUE COMMENT "displayed to the user",
	fk_player_1 BIGINT UNSIGNED COMMENT 'fk to user_accounts',
	fk_player_2 BIGINT UNSIGNED COMMENT 'fk to user_accounts',
	fk_game_type BIGINT UNSIGNED COMMENT 'fk to game type id',
	rated BOOLEAN NOT NULL COMMENT 'if the game is rated',
 	p1_score TINYINT NOT NULL DEFAULT 0 COMMENT 'score of player 1',
 	p2_score TINYINT NOT NULL DEFAULT 0 COMMENT 'score of player 2',
 	is_finished BOOLEAN NOT NULL COMMENT 'if the session finished',
 	started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	KEY key_player_1 (fk_player_1),
	KEY key_player_2 (fk_player_2),
	FOREIGN KEY (fk_game_type) REFERENCES game_types(pk_id), -- on update and delete RESTRICT!
	FOREIGN KEY (fk_player_1) REFERENCES user_accounts(pk_id),
	FOREIGN KEY (fk_player_2) REFERENCES user_accounts(pk_id),
	CONSTRAINT chk_session_uuid CHECK (IS_UUID(session_uuid)) -- verify that value is uuid
) ENGINE=InnoDB;



DROP TABLE IF EXISTS games;
CREATE TABLE games (
	pk_id SERIAL PRIMARY KEY COMMENT 'game identifier',
	fk_session_id BIGINT UNSIGNED NOT NULL COMMENT 'fk to session id',
	fk_winner_user BIGINT UNSIGNED COMMENT 'fk to the winner user id',
	fk_loser_user BIGINT UNSIGNED COMMENT 'fk to the loser user id',
	winner_rate_update TINYINT UNSIGNED COMMENT 'increase rate',
	loser_rate_update TINYINT UNSIGNED COMMENT 'reduce rate by',
	p1_wants_again BOOLEAN DEFAULT False COMMENT 'True if player 1 wants to play again',
	p2_wants_again BOOLEAN DEFAULT False COMMENT 'True if player 2 wants to play again',
	started_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "openning_session timestamp",
	finished_at DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'when the GAME been finsihed',	-- update event = session ending
	FOREIGN KEY (fk_winner_user) REFERENCES user_accounts(pk_id),
	FOREIGN KEY (fk_loser_user) REFERENCES user_accounts(pk_id),
	CONSTRAINT fk_games_session_id FOREIGN KEY (fk_session_id) REFERENCES game_sessions(pk_id)
) ENGINE=InnoDB;



DROP TABLE IF EXISTS session_chat;
CREATE TABLE session_chat (
	pk_msg_id SERIAL PRIMARY KEY COMMENT 'message id',
	fk_session_id BIGINT UNSIGNED NOT NULL COMMENT 'game session',
	body VARCHAR(255) NOT NULL COMMENT 'chat message',   -- 255 big enough for the chat. Empty messages not allowed
	fk_sent_by BIGINT UNSIGNED COMMENT 'fk to sender user id',
	sent_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'openning_session timestamp',
	FOREIGN KEY (fk_sent_by) REFERENCES user_accounts(pk_id),
	FOREIGN KEY (fk_session_id) REFERENCES game_sessions(pk_id)
) ENGINE=InnoDB;



DROP TABLE IF EXISTS moves; 
CREATE TABLE moves (
	pk_id SERIAL PRIMARY KEY COMMENT 'row id',
	game_id BIGINT UNSIGNED NOT NULL,
	move_number INT COMMENT 'actual game move number',
	plays_white TINYINT NOT NULL COMMENT 'who begins',
	game_result TINYINT NOT NULL COMMENT '1 for player 1 won, 2 for player 2 won, 3 for draw, 0 game in progress',
	p1_move VARCHAR(20) COMMENT 'move of player1', -- example value 'e4 e5'
	p2_move VARCHAR(20) COMMENT 'move of player2', -- exanple value 'Nf3 Nc6'
	move_time DATETIME DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT chk_white_player CHECK (plays_white=1 OR plays_white=2),
	CONSTRAINT chk_game_result CHECK (game_result=1 OR game_result=2 OR game_result=3 OR game_result=0 )
) ENGINE=Memory;



DROP TABLE IF EXISTS game_archive;
CREATE TABLE game_archive(
	game_id BIGINT UNSIGNED NOT NULL COMMENT 'game id',
	event BIGINT NOT NULL COMMENT 'game type info',
	white BIGINT NOT NULL COMMENT 'user id of the white player',
	black BIGINT NOT NULL COMMENT 'name of the black player',
	game_result VARCHAR(30) NOT NULL COMMENT 'game resault',
	game_log TEXT COMMENT 'all moves'
) ENGINE=Archive;


 
SET FOREIGN_KEY_CHECKS=1;
COMMIT; 