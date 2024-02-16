### Table Student
1. Trigger before insert which just checks if correct student_id
2. Trigger after insert which updates the valid_entry table by incrementing the sequence for the dept_id of that student
3. Trigger before insert which checks the student email id
4. Created another table student_dept_change
5. Trigger before update which checks if the student is changing the department and if yes and year is >2022 and grade is >8.5, then it updates the student_dept_change table, when making new student_id, update the valid_entry table by incrementing the sequence for the dept_id of that student, also update the email id of the student
6. Trigger after update which would update the student with new student id and email id, also update the student_courses table with new student id, also update the valid_entry table by incrementing the sequence for the dept_id of that student, also insert into the student_dept_change table
   
### Table Student_Courses
1. Create a view course_eval, which stores the course_id, session, semester, number_of_students,avg_grade, max_grade, min_grade for every course in that particular session and semester
2. Trigger before insert which checks if the student is eligible to take the course also updating the student table's total credits and also checking the course capacity and updating the course_offers table with incrementing the enrolledmetss count
3. Trigger before insert which checks that no student is enrolled in more than 5 courses in a session and semester, also check the total credits of the student should be less than 60
4. Trigger before insert which ensures that any course of credits <5 can only be taken by students in the first year
5. Trigger after insert or delete where keep the view updated and also update the course_offers table by decrementing in case of delete but didnt increment in case of insert as it is already done in the before insert trigger
6. Trigger before insert which is checking if the capascity of the course is full or not 
7. Trigger after insert which is updating the course_offers table by incrementing the enrolledmetss count

### Table course_offers
1. Trigger after delete in course_offers which updates the student_courses table
2. Trigger before insert which checks if the course was not already offered and the professor is present in the professor table
3. Trigger before insert which check if prof is not teaching more than 4 courses in a session and semester and also the course session is before his resignation year

### Table department
1. 