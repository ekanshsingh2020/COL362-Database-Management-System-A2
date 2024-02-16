CREATE TABLE department (
    dept_id CHAR(3) PRIMARY KEY,
    dept_name VARCHAR(40) NOT NULL UNIQUE
);
CREATE TABLE courses (
    course_id CHAR(6) PRIMARY KEY,
    course_name VARCHAR(20) NOT NULL UNIQUE,
    course_desc TEXT,
    credits NUMERIC NOT NULL CHECK (credits > 0),
    dept_id CHAR(3) REFERENCES department(dept_id)
);
CREATE TABLE valid_entry (
    dept_id CHAR(3) REFERENCES department(dept_id),
    entry_year INTEGER NOT NULL,
    seq_number INTEGER NOT NULL
);

CREATE TABLE professor (
    professor_id VARCHAR(10) PRIMARY KEY,
    professor_first_name VARCHAR(40) NOT NULL,
    professor_last_name VARCHAR(40) NOT NULL,
    office_number VARCHAR(20),
    contact_number CHAR(10) NOT NULL,
    start_year INTEGER,
    resign_year INTEGER CHECK (start_year <= resign_year),
    dept_id CHAR(3) REFERENCES department(dept_id)
);
CREATE TABLE student (
    first_name VARCHAR(40) NOT NULL,
    last_name VARCHAR(40),
    student_id CHAR(11) PRIMARY KEY,
    address VARCHAR(100),
    contact_number CHAR(10) NOT NULL UNIQUE,
    email_id VARCHAR(50) UNIQUE,
    tot_credits INTEGER NOT NULL CHECK (tot_credits >= 0),
    dept_id CHAR(3) REFERENCES department(dept_id)
);
CREATE TABLE course_offers (
    course_id CHAR(6),
    session VARCHAR(9),
    semester INTEGER NOT NULL CHECK (semester IN (1, 2)),
    professor_id VARCHAR(10),
    capacity INTEGER,
    enrollments INTEGER,
    PRIMARY KEY (course_id, session, semester),
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (professor_id) REFERENCES professor(professor_id)
);
CREATE TABLE student_courses (
    student_id CHAR(11),
    course_id CHAR(6),
    session VARCHAR(9),
    semester INTEGER NOT NULL CHECK (semester IN (1, 2)),
    grade NUMERIC NOT NULL CHECK (grade BETWEEN 0 AND 10),
    FOREIGN KEY (course_id, session, semester) REFERENCES course_offers(course_id, session, semester),
    FOREIGN KEY (student_id) REFERENCES student(student_id)
);

CREATE OR REPLACE FUNCTION validate_course_id_format()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        NEW.course_id LIKE (SELECT CONCAT(dept_id, '___') FROM department) AND
        NEW.course_id SIMILAR TO '___\d{3}'
    ) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'invalid';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER course_id_format_trigger
BEFORE INSERT OR UPDATE ON courses
FOR EACH ROW
EXECUTE FUNCTION validate_course_id_format();



CREATE OR REPLACE FUNCTION validate_student_id_function() RETURNS TRIGGER AS $$
BEGIN
    DECLARE
        entry_year_val INTEGER;
        dept_id_val CHAR(3);
        seq_number_val INTEGER;
        temp CHAR (3);
    BEGIN
        entry_year_val := SUBSTRING(NEW.student_id FROM 1 FOR 4)::INTEGER;
        dept_id_val := SUBSTRING(NEW.student_id FROM 5 FOR 3);
        seq_number_val := SUBSTRING(NEW.student_id FROM 8)::INTEGER;
        SELECT dept_id INTO temp FROM valid_entry WHERE dept_id = dept_id_val AND entry_year = entry_year_val AND seq_number = seq_number_val;
        IF NOT EXISTS (
            SELECT 1 FROM valid_entry 
            WHERE entry_year = entry_year_val AND dept_id = dept_id_val AND seq_number = seq_number_val
        ) THEN
            RAISE EXCEPTION 'invalid';
        END IF;
        IF LENGTH(NEW.student_id) <> 10 THEN
            RAISE EXCEPTION 'invalid';
        END IF;

        RETURN NEW;
    END;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_student_id
BEFORE INSERT ON student
FOR EACH ROW EXECUTE FUNCTION validate_student_id_function();

CREATE OR REPLACE FUNCTION update_seq_number_function() RETURNS TRIGGER AS $$
BEGIN
    UPDATE valid_entry
    SET seq_number = seq_number + 1
    WHERE dept_id = NEW.dept_id AND entry_year=CAST(SUBSTRING(NEW.student_id FROM 1 FOR 4) AS INTEGER);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_seq_number
AFTER INSERT ON student
FOR EACH ROW EXECUTE FUNCTION update_seq_number_function();


CREATE OR REPLACE FUNCTION validate_email_function() RETURNS TRIGGER AS $$
BEGIN
    DECLARE
        student_id_part CHAR(11);
        email_parts TEXT[];
        dept_id_part CHAR(3);
        entry_year_part INTEGER;
        seq_number_part INTEGER;
        length_student_id INTEGER;
        sequence INTEGER;
    BEGIN
        email_parts := string_to_array(NEW.email_id, '@');
        IF array_length(email_parts, 1) = 2 THEN
            student_id_part := SUBSTRING(NEW.email_id FROM 1 FOR 10);
            IF length(student_id_part) <> 10 THEN
                RAISE EXCEPTION 'invalid';
            END IF;
            IF student_id_part != NEW.student_id THEN
                RAISE EXCEPTION 'invalid';
            END IF;
            IF email_parts[2] LIKE (NEW.dept_id || '.iitd.ac.in') THEN
                RETURN NEW;
            ELSE
                RAISE EXCEPTION 'invalid';
            END IF;
        ELSE
            RAISE EXCEPTION 'invalid';
        END IF;
    END;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_email
BEFORE INSERT ON student
FOR EACH ROW EXECUTE FUNCTION validate_email_function();


CREATE TABLE student_dept_change (
    old_student_id CHAR(11),
    old_dept_id CHAR(3) REFERENCES department(dept_id),
    new_dept_id CHAR(3) REFERENCES department(dept_id),
    new_student_id CHAR(11)
);


CREATE OR REPLACE FUNCTION log_student_dept_change()
RETURNS TRIGGER AS $$
BEGIN
    DECLARE entry_yr INTEGER;
    DECLARE new_id CHAR(11);
    DECLARE new_seq_number INTEGER;
    DECLARE new_email_id VARCHAR(50);
    DECLARE avg_grade NUMERIC;
    DECLARE old_student_id CHAR(11);
    DECLARE temp_contact CHAR(10);
    BEGIN
        IF TG_WHEN = 'BEFORE' THEN
            old_student_id := OLD.student_id;
            IF OLD.dept_id = NEW.dept_id THEN
                RETURN NEW;
            END IF;
            entry_yr := CAST(SUBSTRING(OLD.student_id FROM 1 FOR 4) AS INTEGER);
            IF entry_yr < 2022 THEN
                RAISE EXCEPTION 'Entry year must be >= 2022';
            END IF;

            IF EXISTS (
                SELECT 1 FROM student_dept_change 
                WHERE new_student_id = OLD.student_id
            ) THEN
                RAISE EXCEPTION 'Department can be changed only once';
            END IF;
            
            
            SELECT AVG(grade) INTO avg_grade FROM student_courses WHERE student_id = OLD.student_id;
            
            IF avg_grade IS NULL OR avg_grade <= 8.5 THEN
                RAISE EXCEPTION 'Low Grade';
            END IF;

            ELSIF TG_WHEN = 'AFTER' THEN
            IF OLD.dept_id = NEW.dept_id THEN
                RETURN NEW;
            END IF;
            new_id := SUBSTRING(NEW.student_id FROM 1 FOR 4) || NEW.dept_id || LPAD(CAST((SELECT seq_number FROM valid_entry WHERE entry_year = CAST(SUBSTRING(NEW.student_id FROM 1 FOR 4) AS INTEGER) AND dept_id = NEW.dept_id) AS TEXT), 3, '0');
            temp_contact := '1111111111';
            new_email_id := new_id || '@' || NEW.dept_id || '.iitd.ac.in';
            INSERT INTO student
            VALUES (NEW.first_name, NEW.last_name, new_id, NEW.address, temp_contact, new_email_id,NEW.tot_credits, NEW.dept_id);

            UPDATE student_courses 
            SET student_id = new_id
            WHERE student_id = OLD.student_id;
            INSERT INTO student_dept_change 
            VALUES (OLD.student_id, OLD.dept_id, NEW.dept_id, new_id);

            DELETE FROM student WHERE student_id = OLD.student_id;
            UPDATE student
            SET contact_number = NEW.contact_number
            WHERE student_id = new_id;
        END IF;
        
        RETURN NEW;
    END;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_student_update
BEFORE UPDATE ON student
FOR EACH ROW
EXECUTE FUNCTION log_student_dept_change();

CREATE TRIGGER after_student_update
AFTER UPDATE ON student
FOR EACH ROW
EXECUTE FUNCTION log_student_dept_change();






CREATE MATERIALIZED VIEW course_eval AS
SELECT 
    course_id,
    session,
    semester,
    COUNT(*) AS number_of_students,
    AVG(grade) AS average_grade,
    MAX(grade) AS max_grade,
    MIN(grade) AS min_grade
FROM 
    student_courses
GROUP BY 
    course_id, session, semester;


CREATE OR REPLACE FUNCTION refresh_course_eval_view()
RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW course_eval;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_course_eval_view
AFTER INSERT OR DELETE OR UPDATE ON student_courses
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_course_eval_view();


CREATE OR REPLACE FUNCTION update_tot_credits_function()
RETURNS TRIGGER AS $$
DECLARE
    tot_cred_now INTEGER;
    cred_this_course INTEGER;
BEGIN
    IF (
        SELECT COUNT(*)
        FROM student_courses
        WHERE student_id = NEW.student_id AND course_id = NEW.course_id AND session = NEW.session AND semester = NEW.semester
    ) > 0 THEN
        RAISE EXCEPTION 'invalid';
    END IF;


    tot_cred_now := (
        SELECT tot_credits
        FROM student
        WHERE student_id = NEW.student_id
    );

    cred_this_course := (
        SELECT credits
        FROM courses
        WHERE course_id = NEW.course_id
    );

    UPDATE student
    SET tot_credits = tot_cred_now + cred_this_course
    WHERE student_id = NEW.student_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER update_tot_credits
BEFORE INSERT ON student_courses
FOR EACH ROW
EXECUTE FUNCTION update_tot_credits_function();

CREATE OR REPLACE FUNCTION check_course_limit()
RETURNS TRIGGER AS $$
DECLARE
    current_courses INTEGER;
    total_credits INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO current_courses
    FROM student_courses
    WHERE student_id = NEW.student_id
        AND session = NEW.session
        AND semester = NEW.semester;

    IF current_courses >=5 THEN
        RAISE EXCEPTION 'invalid';
    END IF;

    SELECT tot_credits
    INTO total_credits
    FROM student
    WHERE student_id = NEW.student_id;

    IF total_credits + (SELECT credits FROM courses WHERE course_id = NEW.course_id) > 60 THEN
        RAISE EXCEPTION 'invalid';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_course_limit
BEFORE INSERT ON student_courses
FOR EACH ROW
EXECUTE FUNCTION check_course_limit();

CREATE OR REPLACE FUNCTION check_course_credit()
RETURNS TRIGGER AS $$
DECLARE
    student_entry_year INTEGER;
    session_first_year INTEGER;
BEGIN
    student_entry_year := CAST(SUBSTRING(NEW.student_id FROM 1 FOR 4) AS INTEGER);
    session_first_year := CAST(SUBSTRING(NEW.session FROM 1 FOR 4) AS INTEGER);
    IF (SELECT credits FROM courses WHERE course_id = NEW.course_id) >= 5 AND
       (student_entry_year != session_first_year) THEN
        RAISE EXCEPTION 'invalid';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_course_credit
BEFORE INSERT ON student_courses
FOR EACH ROW
EXECUTE FUNCTION check_course_credit();

CREATE MATERIALIZED VIEW student_semester_summary AS
SELECT 
    sc.student_id,
    sc.session,
    sc.semester,
    SUM(CASE WHEN sc.grade>=5.0 THEN sc.grade * c.credits ELSE 0 END) / SUM(CASE WHEN sc.grade >= 5.0 THEN c.credits ELSE 0 END) AS sgpa,
    SUM(CASE WHEN grade >= 5.0 THEN credits ELSE 0 END) AS credits
FROM 
    student_courses sc
    JOIN courses c ON sc.course_id = c.course_id
GROUP BY 
    student_id, session, semester;


CREATE OR REPLACE FUNCTION update_student_courses_insert()
RETURNS TRIGGER AS $$
    DECLARE semester_credits INTEGER;
    DECLARE course_credits INTEGER;
BEGIN
    IF TG_OP = 'INSERT' THEN
        SELECT COALESCE(SUM(credits), 0) INTO semester_credits
        FROM student_courses
        WHERE student_id = NEW.student_id AND session = NEW.session AND semester = NEW.semester;

        SELECT c.credits INTO course_credits
        FROM courses c
        WHERE c.course_id = NEW.course_id;

        IF semester_credits + NEW.credits > 26 THEN
            RAISE EXCEPTION 'invalid';
        END IF;

        REFRESH MATERIALIZED VIEW student_semester_summary;
    ELSE
        UPDATE course_offers
        SET enrollments = enrollments - 1
        WHERE course_id = OLD.course_id AND session = OLD.session AND semester = OLD.semester;
        UPDATE student
        SET tot_credits = tot_credits - (SELECT credits FROM courses WHERE course_id = OLD.course_id)
        WHERE student_id = OLD.student_id;
        REFRESH MATERIALIZED VIEW student_semester_summary;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_student_semester_summary_trigger
AFTER INSERT OR DELETE ON student_courses
FOR EACH ROW
EXECUTE FUNCTION update_student_courses_insert();


CREATE OR REPLACE FUNCTION check_course_capacity()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_WHEN = 'BEFORE' THEN
      IF EXISTS (
          SELECT 1
          FROM course_offers
          WHERE course_id = NEW.course_id
            AND session = NEW.session
            AND semester = NEW.semester
            AND enrollments >= capacity
      ) THEN
          RAISE EXCEPTION 'course is full';
      END IF;

    ELSIF TG_WHEN = 'AFTER' THEN
      UPDATE course_offers
      SET enrollments = enrollments + 1
      WHERE course_id = NEW.course_id
        AND session = NEW.session
        AND semester = NEW.semester;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_course_capacity_trigger_before
BEFORE INSERT ON student_courses
FOR EACH ROW
EXECUTE FUNCTION check_course_capacity();

CREATE TRIGGER check_course_capacity_trigger_after
AFTER INSERT ON student_courses
FOR EACH ROW
EXECUTE FUNCTION check_course_capacity();



CREATE OR REPLACE FUNCTION delete_course_offers_trigger()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM student_courses 
    WHERE course_id = OLD.course_id AND 
          session = OLD.session AND 
          semester = OLD.semester;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_course_offers_trigger
AFTER DELETE ON course_offers
FOR EACH ROW
EXECUTE FUNCTION delete_course_offers_trigger();

CREATE OR REPLACE FUNCTION insert_course_offers_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM courses WHERE course_id = NEW.course_id
    ) THEN
        RAISE EXCEPTION 'invalid';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM professor WHERE professor_id = NEW.professor_id
    ) THEN
        RAISE EXCEPTION 'invalid';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER insert_course_offers_trigger
BEFORE INSERT ON course_offers
FOR EACH ROW
EXECUTE FUNCTION insert_course_offers_trigger();


CREATE OR REPLACE FUNCTION check_course_offers_entry()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM course_offers co
        JOIN professor p ON co.professor_id = p.professor_id
        WHERE co.session = NEW.session
          AND co.professor_id = NEW.professor_id
          AND p.resign_year > CAST(SUBSTRING(NEW.session FROM 1 FOR 4) AS INTEGER)
        GROUP BY co.session, co.professor_id
        HAVING COUNT(*) >= 4
    ) THEN
        RAISE EXCEPTION 'invalid';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM professor p
        WHERE p.professor_id = NEW.professor_id
          AND (p.resign_year <= CAST(SUBSTRING(NEW.session FROM 1 FOR 4) AS INTEGER) OR p.start_year > CAST(SUBSTRING(NEW.session FROM 1 FOR 4) AS INTEGER))
    ) THEN
        RAISE EXCEPTION 'invalid';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER check_course_offers_entry_trigger
BEFORE INSERT ON course_offers
FOR EACH ROW
EXECUTE FUNCTION check_course_offers_entry();