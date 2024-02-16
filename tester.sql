-- Inserting into department table
INSERT INTO department (dept_id, dept_name) VALUES ('CSE', 'Computer Science and Engineering');

-- Inserting into professor table
INSERT INTO professor (professor_id, professor_first_name, professor_last_name, office_number, contact_number, start_year, resign_year, dept_id) 
VALUES ('P001', 'John', 'Doe', 'CSE101', '1234567890', 2015, NULL, 'CSE');

-- Inserting into valid_entry table
INSERT INTO valid_entry (dept_id, entry_year, seq_number) VALUES ('CSE', 2022, 1);

-- Inserting into courses table
INSERT INTO courses (course_id, course_name, course_desc, credits, dept_id) 
VALUES ('CSE101', 'Introduction', 'An introductory course.', 4, 'CSE');

-- Inserting into student table
INSERT INTO student (first_name, last_name, student_id, address, contact_number, email_id, tot_credits, dept_id) 
VALUES ('Alice', 'Smith', '2022CSE001', '123 Main St, City', '9876543210', '2022CSE001@CSE.iitd.ac.in', 16, 'CSE');

-- Inserting into course_offers table
INSERT INTO course_offers (course_id, session, semester, professor_id, capacity, enrollments) 
VALUES ('CSE101', '2023-2024', 1, 'P001', 50, 0);

-- Inserting into student_courses table
INSERT INTO student_courses (student_id, course_id, session, semester, grade) 
VALUES ('2022CSE001', 'CSE101', '2023-2024', 1, 9);

INSERT INTO 
department (dept_id, dept_name)
VALUES ('EEE', 'Electronics');

INSERT INTO
valid_entry (dept_id, entry_year, seq_number) 
VALUES ('EEE', 2022, 1);