-- КУРСОВАЯ РАБОТА ПО КУРСУ "БАЗЫ ДАННЫХ". ТИТАРЧУК К. 
-- ТЕМА: "Модель базы данных сервиса для наставничества и помощи в профориентации".

-- Составим общее текстовое описание БД и решаемых ею задач.
/* 
Основная задача сервиса – расширить внедрение наставничества и гарантировать выполнение условий оферты. 

База данных mentors_service хранит данные, которые образуются в результате использования сервиса пользователями, а именно в случаях:
- регистрации нового пользователя;
- заполнения профиля пользователя;
- заполнения карты ментора(наставника) в целях дальнейшего взаимодействия по предоставлению менторской помощи;
- взаимодействия ментора и ученика по планированию и организации встреч, оказанию менторской помощи;
- оценки активности ментора, подсчета рейтинга ментора и рейтинга ученика.

Основная задача базы данных mentors_service - обеспечить корректную запись и чтение, изменение данных при использовании сервиса для
наставничества и помощи в профориентации посредством веб-интерфейса.
*/

-- Напишем скрипты создания структуры БД. 
DROP DATABASE IF EXISTS mentors_service;
CREATE DATABASE mentors_service;
USE mentors_service;


DROP TABLE IF EXISTS user;
CREATE TABLE user (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	firstname VARCHAR(100) NOT NULL,
	lastname VARCHAR(100) NOT NULL,
	birthday DATE NOT NULL,
	`e-mail` VARCHAR(150) NOT NULL UNIQUE,
	`pass-hash` VARCHAR(255),
	phone BIGINT UNSIGNED NOT NULL UNIQUE,
	created_at DATETIME DEFAULT NOW(),
	is_admin BIT DEFAULT 0,
	
	INDEX idx_first_lastname(firstname, lastname),
	INDEX idx_last_firstname(lastname, firstname)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS admin_list;
CREATE TABLE admin_list (
	id_admin BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE,
	user_id BIGINT UNSIGNED NOT NULL,
	
	FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS country;
CREATE TABLE country (
	country_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE,
	c_name VARCHAR(100) UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS hometown;
CREATE TABLE hometown (
	home_id SERIAL,
	from_country BIGINT UNSIGNED NOT NULL,
	h_name VARCHAR(100) UNIQUE,
	
	FOREIGN KEY (from_country) REFERENCES country(country_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS photo;
CREATE TABLE photo (
	photo_id SERIAL,
	user_id BIGINT UNSIGNED NOT NULL,
	photo_name VARCHAR(255),
	added_at DATETIME DEFAULT NOW(),
	
	FOREIGN KEY (user_id) REFERENCES user(id) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS video_types;
CREATE TABLE video_types (
	id_video_types SERIAL,
	vt_name VARCHAR(100) UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS video_avatar;
CREATE TABLE video_avatar (
	video_id SERIAL,
	user_id BIGINT UNSIGNED NOT NULL,
	video_type_vt_name VARCHAR(100),
	video_name VARCHAR(255),
	video_size_mb INT,
	metadata JSON,
	added_at DATETIME DEFAULT NOW(),
	
	FOREIGN KEY (user_id) REFERENCES user(id),
	FOREIGN KEY (video_type_vt_name) REFERENCES video_types(vt_name) ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS activity_indicator;
CREATE TABLE activity_indicator (
	user_id BIGINT UNSIGNED NOT NULL,
	counter_successfully_meetings INT UNSIGNED DEFAULT 0,
	counter_currently_and_temporarily_stopped INT UNSIGNED DEFAULT 0,
	total_counter INT UNSIGNED DEFAULT 0,
	
	INDEX idx_activity_total_count(total_counter),
	FOREIGN KEY (user_id) REFERENCES user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS rating_student;
CREATE TABLE rating_student (
	user_id BIGINT UNSIGNED NOT NULL,
	counter_student_target INT UNSIGNED DEFAULT 0,
	
	INDEX idx_rating_stud_count(counter_student_target),
	FOREIGN KEY (user_id) REFERENCES user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS rating_mentor;
CREATE TABLE rating_mentor (
	user_id BIGINT UNSIGNED NOT NULL,
	counter_mentor_initiatior INT UNSIGNED DEFAULT 0,
	
	INDEX idx_rating_mentor_count(counter_mentor_initiatior),
	FOREIGN KEY (user_id) REFERENCES user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS profile;
CREATE TABLE profile (
	user_id BIGINT UNSIGNED NOT NULL,
	user_age INT UNSIGNED NOT NULL,
	gender ENUM('мужчина', 'женщина'),
	country_c_name VARCHAR(100) NOT NULL,
	hometown_h_name VARCHAR(100) NOT NULL,
	photo_photo_id BIGINT UNSIGNED DEFAULT NULL,
	video_avatar_video_id BIGINT UNSIGNED DEFAULT NULL,
	about_me TEXT, -- ElasticSearch
	current_place_of_work VARCHAR(150),
	previous_jobs TEXT,
	rating_mentor_counter_mentor_initiatior INT UNSIGNED,
	rating_student_counter_student_target INT UNSIGNED,
	activity_indicator_total_counter INT UNSIGNED,
	
	INDEX idx_gender(gender),
	INDEX idx_cur_pl_of_work(current_place_of_work),
	FULLTEXT KEY idx_about_me(about_me),
	FULLTEXT KEY idx_prev_jobs(previous_jobs),
	FOREIGN KEY (user_id) REFERENCES user(id),
	FOREIGN KEY (country_c_name) REFERENCES country(c_name) ON UPDATE RESTRICT,
	FOREIGN KEY (hometown_h_name) REFERENCES hometown(h_name) ON UPDATE RESTRICT,
	FOREIGN KEY (photo_photo_id) REFERENCES photo(photo_id) ON UPDATE CASCADE,
	FOREIGN KEY (video_avatar_video_id) REFERENCES video_avatar(video_id) ON UPDATE CASCADE,
	FOREIGN KEY (rating_mentor_counter_mentor_initiatior) REFERENCES rating_mentor(counter_mentor_initiatior) ON UPDATE CASCADE,
	FOREIGN KEY (rating_student_counter_student_target) REFERENCES rating_student(counter_student_target) ON UPDATE CASCADE,
	FOREIGN KEY (activity_indicator_total_counter) REFERENCES activity_indicator(total_counter) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS sector_of_mentoring;
CREATE TABLE sector_of_mentoring (
	id_sector SERIAL,
	s_name VARCHAR(255) UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS meeting_suggestion;
CREATE TABLE meeting_suggestion (
	id_meeting SERIAL,
	from_user_id BIGINT UNSIGNED NOT NULL,
	to_user_id BIGINT UNSIGNED NOT NULL,
	message_to TEXT,
	status_invation ENUM('viewed', 'approved', 'rejected'),
	message_from TEXT,
	time_suggested_by_mentor DATETIME DEFAULT NULL,
	meeting_datetime DATETIME DEFAULT NULL,
	meeting_success_status ENUM('success', 'failure', 'in progress'),
	
	FOREIGN KEY (from_user_id) REFERENCES user(id),
	FOREIGN KEY (to_user_id) REFERENCES user(id),
	CHECK (from_user_id != to_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS reviews_of_student;
CREATE TABLE reviews_of_student (
	from_user_id_review BIGINT UNSIGNED NOT NULL,
	to_user_id_review BIGINT UNSIGNED NOT NULL,
	message_of_review TEXT,
	estimation_from_student FLOAT,
	responce_of_mentor TEXT,
	
	FOREIGN KEY (from_user_id_review) REFERENCES user(id),
	FOREIGN KEY (to_user_id_review) REFERENCES user(id),
	CHECK (from_user_id_review != to_user_id_review)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS mentoring_card;
CREATE TABLE mentoring_card (
	id_card SERIAL,
	user_id BIGINT UNSIGNED NOT NULL,
	photo_photo_id BIGINT UNSIGNED NOT NULL,
	rating_mentor_counter_mentor_initiatior INT UNSIGNED DEFAULT NULL,
	rating_student_counter_student_target INT UNSIGNED DEFAULT NULL,
	activity_indicator_total_counter INT UNSIGNED DEFAULT NULL,
	sector_of_mentoring_s_name VARCHAR(255),
	direction_of_mentoring VARCHAR(255),
	description_from_mentor TEXT,
	preliminary_price_of_mentoring INT NOT NULL,
	reviews_of_student_total_estimation FLOAT DEFAULT NULL,
	
	INDEX idx_direction_of_ment(direction_of_mentoring),
	INDEX idx_preliminary_price(preliminary_price_of_mentoring),
	INDEX idx_reviews_of_stud_total(reviews_of_student_total_estimation),
	FOREIGN KEY (user_id) REFERENCES user(id),
	FOREIGN KEY (photo_photo_id) REFERENCES photo(photo_id) ON UPDATE CASCADE,
	FOREIGN KEY (rating_mentor_counter_mentor_initiatior) REFERENCES rating_mentor(counter_mentor_initiatior) ON UPDATE CASCADE,
	FOREIGN KEY (rating_student_counter_student_target) REFERENCES rating_student(counter_student_target) ON UPDATE CASCADE,
	FOREIGN KEY (activity_indicator_total_counter) REFERENCES activity_indicator(total_counter) ON UPDATE CASCADE,
	FOREIGN KEY (sector_of_mentoring_s_name) REFERENCES sector_of_mentoring(s_name) ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS list_of_mentoring;
CREATE TABLE list_of_mentoring (
	mentor_initiator_user_id BIGINT UNSIGNED NOT NULL,
	student_target_user_id BIGINT UNSIGNED NOT NULL,
	status_of_mentoring ENUM('sent', 'currently', 'ended', 'temporarily_stopped', 'rejection_by_student'),
	
	FOREIGN KEY (mentor_initiator_user_id) REFERENCES user(id),
	FOREIGN KEY (student_target_user_id) REFERENCES user(id),
	CHECK (mentor_initiator_user_id != student_target_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS successfully_mentored_people_list;
CREATE TABLE successfully_mentored_people_list (
	from_mentor_request BIGINT UNSIGNED NOT NULL,
	to_student_opinion BIGINT UNSIGNED NOT NULL,
	status_success ENUM('approved', 'rejected'),
	
	FOREIGN KEY (from_mentor_request) REFERENCES user(id),
	FOREIGN KEY (to_student_opinion) REFERENCES user(id),
	CHECK (from_mentor_request != to_student_opinion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS pay_account;
CREATE TABLE pay_account (
	id_pay_account INT(9) ZEROFILL UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	id_pay_user BIGINT UNSIGNED,
	pay_balance BIGINT UNSIGNED,
	refill_balance BIGINT UNSIGNED,
	removal_balance BIGINT UNSIGNED,
	
	FOREIGN KEY (id_pay_user) REFERENCES user(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS logs_all;
CREATE TABLE logs_all (
	id_logsall SERIAL,
	date_of_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
	name_of_tables VARCHAR(150),
	id_inserting_in_tables BIGINT UNSIGNED,
	content_of_field_name_in_tables VARCHAR(255)
 ) ENGINE=Archive;

DROP TABLE IF EXISTS logs_user;
CREATE TABLE logs_user (
	id_logsuser SERIAL,
	user_id BIGINT UNSIGNED NOT NULL,
	login_at DATETIME DEFAULT NOW(),
	logout_at DATETIME DEFAULT NOW()
) ENGINE=Archive;

-- --------------------------------------------------------------------------------------------------------------------------
-- Напишем скрипты наполнения БД данными.
-- Пользователь заходит на сервис и создает нового пользователя (добавим 5 пользователей)
INSERT INTO user(firstname, lastname, birthday, `e-mail`, phone) VALUES
('Ivan', 'Krasnov', '1988-05-05', '33233@mail.ru', '+7950656675'),
('Petr', 'Popov', '1989-05-01', 'pop89@mail.ru', '+7900656470'),
('Karen', 'Sargs', '1990-08-08', 'karenthe@mail.ru', '+7950656000'),
('Lidiya', 'Sokolova', '1995-02-04', 'rock001@mail.ru', '+7055566615'),
('Gabriel', 'Svanski', '1991-05-06', 'masteriu@mail.ru', '+7990656625');

-- Созданный пользователь формирует свой профиль, но сначала заполним родительские таблицы
-- и таблицу с админами сервиса
INSERT INTO admin_list(user_id) VALUES
(2);
-- Сразу же обновим колонку is_admin в таблице users (в этот раз вручную)
UPDATE user
SET is_admin = 1
WHERE id = 2;

INSERT INTO country(c_name) VALUES
('Россия'), ('Польша'), ('Белоруссия'), ('Украина'), ('Эстония');

INSERT INTO hometown(from_country, h_name) VALUES
(1, 'Москва'), (1, 'Санкт-Петербург'), (2, 'Варшава'), (3, 'Минск'), (4, 'Киев'), (5, 'Таллин');

INSERT INTO photo(user_id, photo_name) VALUES
(1, 'myphoto1'), (2, 'myphoto2'), (3, 'myphoto3'), (4, 'myphoto4'), (5, 'myphoto5');

INSERT INTO video_types(vt_name) VALUES
('mp4'), ('avi'), ('mkv'), ('wmv');

INSERT INTO video_avatar(user_id, video_type_vt_name, video_name, video_size_mb) VALUES
(1, 'mp4', 'myvideo1', 650), (2, 'mp4', 'myvideo2', 551), (3, 'avi', 'myvideo3', 602),
(3, 'mkv', 'myvideo4', 302), (5, 'avi', 'myvideo5', 555);

-- Вставим данные в таблицу profiles
INSERT INTO profile(user_id, user_age, gender, country_c_name, hometown_h_name, photo_photo_id, video_avatar_video_id,
about_me, current_place_of_work, previous_jobs) VALUES
(1,
(TIMESTAMPDIFF(YEAR, (SELECT birthday FROM user WHERE id = 1), CURRENT_DATE)),
'мужчина',
'Россия',
'Москва',
(SELECT photo_id FROM photo WHERE user_id = 1 ORDER BY photo_id DESC LIMIT 1),
(SELECT video_id FROM video_avatar WHERE user_id = 1 ORDER BY video_id DESC LIMIT 1),
'Лучший специалист в своем деле',
"ООО 'Стройкомплект'",
"ООО 'Стройнастил'"),

(2,
(TIMESTAMPDIFF(YEAR, (SELECT birthday FROM user WHERE id = 2), CURRENT_DATE)),
'мужчина',
'Россия',
'Москва',
(SELECT photo_id FROM photo WHERE user_id = 2 ORDER BY photo_id DESC LIMIT 1),
(SELECT video_id FROM video_avatar WHERE user_id = 2 ORDER BY video_id DESC LIMIT 1),
'Высококвалифицированный специалист',
"ООО 'Кошкиндом'",
"Отсутствует"),

(3,
(TIMESTAMPDIFF(YEAR, (SELECT birthday FROM user WHERE id = 3), CURRENT_DATE)),
'мужчина',
'Украина',
'Киев',
(SELECT photo_id FROM photo WHERE user_id = 3 ORDER BY photo_id DESC LIMIT 1),
(SELECT video_id FROM video_avatar WHERE user_id = 3 ORDER BY video_id DESC LIMIT 1),
'Имею большой стаж',
"ООО 'Полушка'",
"Магнит, Пятёрочка, Дикси"),

(4,
(TIMESTAMPDIFF(YEAR, (SELECT birthday FROM user WHERE id = 4), CURRENT_DATE)),
'женщина',
'Белоруссия',
'Минск',
(SELECT photo_id FROM photo WHERE user_id = 4 ORDER BY photo_id DESC LIMIT 1),
(SELECT video_id FROM video_avatar WHERE user_id = 4 ORDER BY video_id DESC LIMIT 1),
'Хороший специалист',
"Кондитер и КО",
"Конфентпром"),

(5,
(TIMESTAMPDIFF(YEAR, (SELECT birthday FROM user WHERE id = 5), CURRENT_DATE)),
'женщина',
'Польша',
'Варшава',
(SELECT photo_id FROM photo WHERE user_id = 5 ORDER BY photo_id DESC LIMIT 1),
(SELECT video_id FROM video_avatar WHERE user_id = 5 ORDER BY video_id DESC LIMIT 1),
'Многое знаю',
"Карамба",
"Кракатум, Ромопор. Долгое время работала в этих компаниях и приобрела уникальные знания");

-- Дальше пользователь может пополнить баланс средств на своем счету (немного упрощенный вид таблицы, для примера)
INSERT INTO pay_account VALUES
(NULL, 1, 0, 0, 0);

UPDATE pay_account
SET 
	pay_balance = 500,
	refill_balance = 500
WHERE id_pay_user = 1;

-- Пользователь может создать/заполнить карточку ментора
INSERT INTO reviews_of_student VALUES
(1, 2, 'Превосходный наставник', 8.5, ''),
(1, 3, 'Получил много знаний от наставника', 8.0, ''),
(1, 4, 'Получил много знаний от наставника', 7.0, ''),
(1, 5, 'Получил хорошие знания', 6.5, ''),
(2, 1, 'Получил много знаний от наставника', 10.0, ''),
(2, 3, 'Получил много знаний от наставника', 10.0, ''),
(2, 4, 'Получил много знаний от наставника', 9.0, ''),
(2, 5, 'Получил много знаний от наставника', 8.5, ''),
(3, 1, 'Получил много знаний от наставника', 9.0, ''),
(3, 2, 'Получил много знаний от наставника', 7.5, ''),
(3, 4, 'Хороший наставник', 6.0, ''),
(3, 5, 'Получил много знаний от наставника', 10.0, ''),
(4, 1, 'Получил много знаний от наставника', 9.0, ''),
(4, 2, 'Получил много знаний от наставника', 9.5, ''),
(4, 3, 'Можно было и лучше', 5.5, ''),
(4, 5, 'Получил много знаний от наставника', 10.0, ''),
(5, 1, 'Получил много знаний от наставника', 9.0, ''),
(5, 2, 'Получил много знаний от наставника', 9.5, ''),
(5, 3, 'Получил много знаний от наставника', 8.0, ''),
(5, 4, 'Получил много знаний от наставника', 8.5, '');

INSERT INTO sector_of_mentoring(s_name) VALUES
('IT'), ('Телеком'), ('Связь'), ('Маркетинг'), ('Экономика предприятия');

INSERT INTO mentoring_card VALUES
(NULL, 1, (SELECT photo_id FROM photo WHERE user_id = 1 ORDER BY photo_id DESC LIMIT 1), DEFAULT, DEFAULT, DEFAULT, 'Телеком',
'Цифровое телевидение', 'Перспективная область для выского заработка, моё наставничество сможет в этом помочь.',
500, (ROUND((SELECT AVG(estimation_from_student) FROM reviews_of_student WHERE to_user_id_review = 1), 2))),

(NULL, 2, (SELECT photo_id FROM photo WHERE user_id = 2 ORDER BY photo_id DESC LIMIT 1), DEFAULT, DEFAULT, DEFAULT, 'IT',
'Веб-дизайн', 'Помогу сделать красивый сайт.',
500, (ROUND((SELECT AVG(estimation_from_student) FROM reviews_of_student WHERE to_user_id_review = 2), 2))),

(NULL, 3, (SELECT photo_id FROM photo WHERE user_id = 3 ORDER BY photo_id DESC LIMIT 1), DEFAULT, DEFAULT, DEFAULT, 'IT',
'Верстка', 'Помогу сделать все правильно.',
550, (ROUND((SELECT AVG(estimation_from_student) FROM reviews_of_student WHERE to_user_id_review = 3), 2))),

(NULL, 4, (SELECT photo_id FROM photo WHERE user_id = 4 ORDER BY photo_id DESC LIMIT 1), DEFAULT, DEFAULT, DEFAULT, 'Связь',
'Сотовая связь', 'Перспективная область для заработка.',
1000, (ROUND((SELECT AVG(estimation_from_student) FROM reviews_of_student WHERE to_user_id_review = 4), 2))),

(NULL, 5, (SELECT photo_id FROM photo WHERE user_id = 5 ORDER BY photo_id DESC LIMIT 1), DEFAULT, DEFAULT, DEFAULT, 'Экономика предприятия',
'Риск-менеджмент', 'Помогу с расчетами и насущными задачами экономиста.',
2000, (ROUND((SELECT AVG(estimation_from_student) FROM reviews_of_student WHERE to_user_id_review = 5), 2)));


-- Используем для примера ALTER TABLE, чтобы модифицировать таблицу (возможно кое-что забыли при проетировании)
#В проекте ВЕРНУТЬ потом корректные значения в таблицу meeting_suggestion, удалить ALTER TABLE !
ALTER TABLE meeting_suggestion MODIFY COLUMN status_invation ENUM('sent','viewed', 'approved', 'rejected');
ALTER TABLE meeting_suggestion MODIFY COLUMN meeting_success_status ENUM('success', 'failure', 'in progress') DEFAULT 'in progress';

-- Допустим в процессе заполнения таблиц данными стало ясно, что таблицы избыточны, приведем их к номальной форме
#В проекте потом убрать заранее ненужные колонки в таблице и не делать ALTER TABLE (который написан для примера) !!!
ALTER TABLE profile DROP FOREIGN KEY `profile_ibfk_4`;
ALTER TABLE profile DROP FOREIGN KEY `profile_ibfk_5`;
ALTER TABLE profile DROP FOREIGN KEY `profile_ibfk_6`;
ALTER TABLE profile DROP FOREIGN KEY `profile_ibfk_7`;
ALTER TABLE profile DROP FOREIGN KEY `profile_ibfk_8`;
ALTER TABLE profile DROP COLUMN photo_photo_id;
ALTER TABLE profile DROP COLUMN video_avatar_video_id;
ALTER TABLE profile DROP COLUMN rating_mentor_counter_mentor_initiatior;
ALTER TABLE profile DROP COLUMN rating_student_counter_student_target;
ALTER TABLE profile DROP COLUMN activity_indicator_total_counter;

ALTER TABLE mentoring_card DROP FOREIGN KEY `mentoring_card_ibfk_2`;
ALTER TABLE mentoring_card DROP FOREIGN KEY `mentoring_card_ibfk_3`;
ALTER TABLE mentoring_card DROP FOREIGN KEY `mentoring_card_ibfk_4`;
ALTER TABLE mentoring_card DROP FOREIGN KEY `mentoring_card_ibfk_5`;
ALTER TABLE mentoring_card DROP COLUMN photo_photo_id;
ALTER TABLE mentoring_card DROP COLUMN rating_mentor_counter_mentor_initiatior;
ALTER TABLE mentoring_card DROP COLUMN rating_student_counter_student_target;
ALTER TABLE mentoring_card DROP COLUMN activity_indicator_total_counter;


-- Напишем несколько необходимых триггеров
DROP TRIGGER IF EXISTS autofill_table_activity1;
DELIMITER //
CREATE TRIGGER autofill_table_activity1 AFTER UPDATE ON meeting_suggestion
FOR EACH ROW
BEGIN 
	IF NEW.meeting_success_status = 'success' THEN 
		IF NEW.to_user_id NOT IN (SELECT user_id FROM activity_indicator) THEN 
			INSERT INTO activity_indicator VALUES
			(NEW.to_user_id, (SELECT COUNT(meeting_success_status) FROM meeting_suggestion
				WHERE meeting_success_status = 'success' AND to_user_id = NEW.to_user_id),
			DEFAULT, DEFAULT);
		UPDATE activity_indicator
		SET total_counter = (counter_successfully_meetings + counter_currently_and_temporarily_stopped)
		WHERE user_id = NEW.to_user_id;

		ELSE
			UPDATE activity_indicator
			SET counter_successfully_meetings = (SELECT COUNT(meeting_success_status) FROM meeting_suggestion
				WHERE meeting_success_status = 'success' AND to_user_id = NEW.to_user_id)
			WHERE user_id = NEW.to_user_id;
		
			UPDATE activity_indicator
			SET total_counter = (counter_successfully_meetings + counter_currently_and_temporarily_stopped)
			WHERE user_id = NEW.to_user_id;
		END IF;	
	END IF;
END//
-- -----------------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS autofill_table_activity2;
DELIMITER //
CREATE TRIGGER autofill_table_activity2 AFTER UPDATE ON list_of_mentoring
FOR EACH ROW
BEGIN 
	IF NEW.status_of_mentoring  = 'currently' OR NEW.status_of_mentoring  = 'temporarily_stopped' THEN 
		UPDATE activity_indicator
		SET counter_currently_and_temporarily_stopped = (SELECT COUNT(mentor_initiator_user_id) FROM list_of_mentoring
			WHERE (status_of_mentoring = 'currently' OR status_of_mentoring = 'temporarily_stopped') AND mentor_initiator_user_id = NEW.mentor_initiator_user_id)
		WHERE user_id = NEW.mentor_initiator_user_id;
		
		UPDATE activity_indicator
		SET total_counter = (counter_successfully_meetings + counter_currently_and_temporarily_stopped)
		WHERE user_id =  NEW.mentor_initiator_user_id;
	END IF;
END//
-- ------------------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS autofill_table_rating_student;
DELIMITER //
CREATE TRIGGER autofill_table_rating_student AFTER UPDATE ON list_of_mentoring
FOR EACH ROW 
BEGIN 
	IF NEW.status_of_mentoring = 'currently' OR NEW.status_of_mentoring = 'temporarily_stopped' THEN 
		IF NEW.student_target_user_id NOT IN (SELECT user_id FROM rating_student) THEN
			INSERT INTO rating_student VALUES
			(NEW.student_target_user_id, (SELECT COUNT(student_target_user_id) FROM list_of_mentoring 
				WHERE student_target_user_id = NEW.student_target_user_id));
		ELSE
			UPDATE rating_student
			SET counter_student_target = (SELECT COUNT(student_target_user_id) FROM list_of_mentoring 
				WHERE student_target_user_id = NEW.student_target_user_id)
			WHERE user_id = NEW.student_target_user_id;
		END IF;
	END IF;
END//
-- -------------------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS autofill_table_rating_mentor;
DELIMITER //
CREATE TRIGGER autofill_table_rating_mentor AFTER UPDATE ON list_of_mentoring
FOR EACH ROW 
BEGIN 
	IF NEW.status_of_mentoring = 'currently' OR NEW.status_of_mentoring = 'temporarily_stopped' THEN 
		IF NEW.mentor_initiator_user_id NOT IN (SELECT user_id FROM rating_mentor) THEN
			INSERT INTO rating_mentor VALUES
			(NEW.mentor_initiator_user_id, (SELECT COUNT(mentor_initiator_user_id) FROM list_of_mentoring 
				WHERE mentor_initiator_user_id = NEW.mentor_initiator_user_id));
		ELSE
			UPDATE rating_mentor
			SET counter_mentor_initiatior = (SELECT COUNT(mentor_initiator_user_id) FROM list_of_mentoring 
				WHERE mentor_initiator_user_id = NEW.mentor_initiator_user_id)
			WHERE user_id = NEW.mentor_initiator_user_id;
		END IF;
	END IF;
END//
DELIMITER ;

-- Заполним оставшиеся таблицы
INSERT INTO meeting_suggestion VALUES
(NULL, 1, 2, 'Станьте моим наставником.', 'sent', '', DEFAULT, DEFAULT, DEFAULT),
(NULL, 1, 3, 'Станьте моим наставником.', 'sent', '', DEFAULT, DEFAULT, DEFAULT),
(NULL, 2, 4, 'Станьте моим наставником.', 'sent', '', DEFAULT, DEFAULT, DEFAULT),
(NULL, 3, 1, 'Станьте моим наставником.', 'sent', '', DEFAULT, DEFAULT, DEFAULT),
(NULL, 3, 4, 'Станьте моим наставником.', 'sent', '', DEFAULT, DEFAULT, DEFAULT),
(NULL, 4, 2, 'Станьте моим наставником.', 'sent', '', DEFAULT, DEFAULT, DEFAULT),
(NULL, 4, 5, 'Станьте моим наставником.', 'sent', '', DEFAULT, DEFAULT, DEFAULT),
(NULL, 5, 3, 'Станьте моим наставником.', 'sent', '', DEFAULT, DEFAULT, DEFAULT),
(NULL, 5, 1, 'Станьте моим наставником.', 'sent', '', DEFAULT, DEFAULT, DEFAULT),
-- вставим еще повторяющуюся запись, чтобы посмотреть как работают триггеры
(NULL, 1, 2, 'Станьте2 моим наставником.', 'sent', '', DEFAULT, DEFAULT, DEFAULT);

UPDATE meeting_suggestion 
SET meeting_success_status = 'success'
WHERE (from_user_id = 1 AND to_user_id = 2) OR
	(from_user_id = 2 AND to_user_id = 4) OR
	(from_user_id = 3 AND to_user_id = 1) OR
	(from_user_id = 4 AND to_user_id = 2) OR
	(from_user_id = 5 AND to_user_id = 3);

INSERT INTO list_of_mentoring VALUES
(2, 1, 'sent'),
(4, 2, 'sent'),
(1, 3, 'sent'),
(2, 4, 'sent'),
(3, 5, 'sent'),
-- вставим еще повторяющуюся запись, чтобы посмотреть как работают триггеры
(2, 1, 'sent');

UPDATE list_of_mentoring
SET status_of_mentoring = 'currently'
WHERE (mentor_initiator_user_id = 2 AND student_target_user_id = 1) OR
	(mentor_initiator_user_id = 4 AND student_target_user_id = 2) OR
	(mentor_initiator_user_id = 1 AND student_target_user_id = 3) OR
	(mentor_initiator_user_id = 2 AND student_target_user_id = 4) OR
	(mentor_initiator_user_id = 3 AND student_target_user_id = 5);

INSERT INTO successfully_mentored_people_list VALUES
(2, 1, 'approved'),
(4, 2, 'approved'),
(1, 3, 'approved'),
(2, 4, 'approved'),
(3, 5, 'approved');

-- ----------------------------------------------------------------------------------------------------------------------
-- Напишем нескоколько необходимых представлений

-- Создадим предстваление card_of_very_activities_ment, которое будет содержать необходимую информацию о самых активных менторах.
DROP PROCEDURE IF EXISTS list_of_very_active_mentors;
DELIMITER //
CREATE PROCEDURE list_of_very_active_mentors()
BEGIN
	IF ((SELECT user_id FROM activity_indicator LIMIT 1) IS NOT NULL AND 
		(SELECT user_id FROM rating_student LIMIT 1) IS NOT NULL AND
		(SELECT user_id FROM rating_mentor LIMIT 1) IS NOT NULL) THEN 
			DROP VIEW IF EXISTS card_of_very_activities_ment;
			CREATE OR REPLACE VIEW card_of_very_activities_ment
			AS
			SELECT 
				user.id, user.firstname, user.lastname, 
				activity_indicator.total_counter AS mentor_activity,
				rating_student.counter_student_target AS student_raiting,
				rating_mentor.counter_mentor_initiatior AS mentor_raiting 
			FROM user
			JOIN activity_indicator ON activity_indicator.user_id = user.id
			JOIN rating_student ON rating_student.user_id = user.id
			JOIN rating_mentor ON rating_mentor.user_id = user.id
			WITH CHECK OPTION;
	ELSEIF ((SELECT user_id FROM activity_indicator LIMIT 1) IS NOT NULL AND 
		(SELECT user_id FROM rating_student LIMIT 1) IS NULL AND
		(SELECT user_id FROM rating_mentor LIMIT 1) IS NOT NULL) THEN 
			DROP VIEW IF EXISTS card_of_very_activities_ment;
			CREATE OR REPLACE VIEW card_of_very_activities_ment
			AS
			SELECT 
				user.id, user.firstname, user.lastname, 
				activity_indicator.total_counter AS mentor_activity,
				rating_mentor.counter_mentor_initiatior AS mentor_raiting 
			FROM user
			JOIN activity_indicator ON activity_indicator.user_id = user.id
			JOIN rating_mentor ON rating_mentor.user_id = user.id
			WITH CHECK OPTION;	
	END IF;
END//
DELIMITER ;
CALL list_of_very_active_mentors(); 

-- Создадим еще одно представление того, что будет отображаться в карте ментора при просмотре карты другими пользователемя. 
DROP VIEW IF EXISTS mentors_card;
CREATE OR REPLACE VIEW mentors_card
AS
SELECT 
	user.id, user.firstname AS 'Имя', user.lastname AS 'Фамилия', photo.photo_id AS 'Фото',
	profile.user_age AS 'Возраст', profile.gender AS 'Пол', profile.hometown_h_name AS 'Город',
	mentoring_card.sector_of_mentoring_s_name AS 'Сфера деятельности', mentoring_card.direction_of_mentoring AS 'Направление деятельности', 
	mentoring_card.description_from_mentor 'Описание', mentoring_card.preliminary_price_of_mentoring AS 'Предварительная цена',
	mentoring_card.reviews_of_student_total_estimation AS 'Средний балл от студентов'
FROM mentoring_card
JOIN user ON user.id = mentoring_card.user_id 
JOIN profile ON profile.user_id = mentoring_card.user_id 
JOIN photo ON photo.user_id = mentoring_card.user_id
WITH CHECK OPTION;

-- SELECT * FROM card_of_very_activities_ment;
-- SELECT * FROM mentors_card;
 

-- КОНЕЦ КУРСОВОЙ РАБОТЫ.