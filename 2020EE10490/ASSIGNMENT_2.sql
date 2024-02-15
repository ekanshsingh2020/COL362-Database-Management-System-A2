-- I have first given you some overview of all the tables, then the schema of all these tables, then the NOT NULL, UNIQUE and Key Constraints and finally given the check constraints.

-- Now analyse all of this and give the queries for all the tables

-- Table_Name | Description
-- student | Stores the basic details of students
-- courses | Stores the details of courses offered in IITD
-- student | courses Stores details about the courses taken by students
-- course_offers | Stores details about which semester offers which course
-- professor | Stores the basic details of professors
-- valid_entry | Stores the current intake cycle/ useful for giving entry id to students
-- department | Stores the details of departments in IITD

-- Table 2: All Tables



-- Column_Name | Data_Type | Description
-- first_name | VARCHAR(40) |
-- last_name | VARCHAR(40) |
-- student_id | CHAR(11) | Primary Key
-- address | VARCHAR(100) |
-- contact_number | CHAR(10) |
-- email_id | VARCHAR(50) |
-- tot_credits | INTEGER |
-- dept_id | ref Table 9 | Foreign Key

-- Table 3: student (tot_credits represents total credits taken by a student and is not dependent on grade. Simply, it
-- is the sum of credits in student_courses table grouped by student_id.)



-- Column_Name | Data_Type | Description
-- course_id | CHAR(6) | Primary Key
-- course_name | VARCHAR(20) |
-- course_desc | TEXT |
-- credits | NUMERIC |
-- dept_id | ref Table 9 | Foreign Key

-- Table 4: courses



-- Column_Name | Data_Type | Description
-- student_id | ref Table 3 | Foreign Key
-- course_id | ref Table 6 | Foreign Key
-- session | ref Table 6 | Foreign Key
-- semester | ref Table 6 | Foreign Key
-- grade | NUMERIC

-- Table 5: student_courses (Here [course_id, session, semester] combined act as a Foreign Key to Table 6)



-- Column_Name | Data_Type | Description
-- course_id | ref Table 4 | Foreign Key, Primary Key
-- session | VARCHAR(9) | Primary Key
-- semester | INTEGER | Primary Key
-- professor_id | ref Table 7 | Foreign Key
-- capacity | INTEGER |
-- enrollments | INTEGER |

-- Table 6: course_offers (Here [course_id, session, semester] combined act as a Primary Key)



-- Column_Name | Data_Type | Description
-- professor_id | VARCHAR(10) | Primary Key
-- professor_first_name | VARCHAR(40) |
-- professor_last_name | VARCHAR(40) |
-- office_number | VARCHAR(20) |
-- contact_number | CHAR(10) |
-- start_year | INTEGER |
-- resign_year | INTEGER |
-- dept_id | ref Table 9 | Foreign Key

-- Table 7: professor



-- Column_Name | Data_Type | Description
-- dept_id | ref Table 9 | Foreign Key
-- entry_year | INTEGER |
-- seq_number | INTEGER |

-- Table 8: valid_entry



-- Column_Name | Data_Type | Description
-- dept_id | CHAR(3) | Primary Key
-- dept_name | VARCHAR(40) |

-- Table 9: department




-- Now lets see some Single Table Constraints on these tables:

-- Your first task as a database designer is to create an initial schema for all the tables with attributes and their
-- abovementioned types. Adhere to the Primary Key and Foreign Key constraints, and use the same names for
-- the tables and the columns. Additionally, add the database requirements calls for the following single table Not
-- NULL, Unique, and check constraints:

-- 1.1 Not NULL and Unique Constraints:


-- Column_Name | Constraint
-- first_name | NOT NULL
-- student_id | NOT NULL
-- contact_number | NOT NULL, UNIQUE
-- email_id | UNIQUE
-- tot_credits | NOT NULL

-- Table 10: student



-- Column_Name | Constraint
-- course_id | NOT NULL
-- course_name | NOT NULL, UNIQUE
-- credits | NOT NULL

-- Table 11: courses



-- Column_Name | Constraint
-- grade | NOT NULL

-- Table 12: student_courses



-- Column_Name | Constraint
-- semester | NOT NULL

-- Table 13: course_offers



-- Column_Name | Constraint
-- professor_first_name | NOT NULL
-- professor_last_name | NOT NULL
-- contact_numner | NOT NULL

-- Table 14: professor



-- Column_Name | Constraint
-- entry_year | NOT NULL
-- seq_number | NOT NULL

-- Table 15: valid_entry



-- Column_Name | Constraint
-- dept_name | NOT NULL, UNIQUE

-- Table 16: department




-- 1.2 Now also incorporate Check Constraints:
-- 1. tot_credits in the student table should be greater than or equal to 0.
-- 2. credits in the courses table should be greater than 0.
-- 3. grade in student_courses should be between 0 and 10 (inclusive).
-- 4. start_year should be less than or equal to resign_year in the professor table.
-- 5. semester should either be 1 or 2 in course_offers and student_courses tables.
-- 6. course_id must have first 3 characters as some dept_id and next 3 characters must be digits


-- Now you have to write the queries for all the tables.

