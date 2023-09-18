-- LeetCode 176. Second Highest Salary
-- https://leetcode.com/problems/second-highest-salary/
/*
Create table If Not Exists Employee (id int, salary int);
Truncate table Employee;
insert into Employee (id, salary) values ('1', '100');
insert into Employee (id, salary) values ('2', '200');
insert into Employee (id, salary) values ('3', '300');
*/

/**
  1. ORDER BY and LIMIT-OFFSET in Scalar Subquery
 */
SELECT (
    SELECT DISTINCT
        salary AS SecondHighestSalary
    FROM Employee
    ORDER BY salary DESC
    LIMIT 1 OFFSET 1
) AS SecondHighestSalary;

/**
  2. ORDER BY and LIMIT-OFFSET in subquery
 */
SELECT
    SecondHighestSalary
FROM (
    SELECT DISTINCT
        salary AS SecondHighestSalary
    FROM Employee
    ORDER BY salary DESC
    LIMIT 1 offset 1
) AS tmp
UNION (
    SELECT null FROM DUAL
)
LIMIT 1;

/*
 3. Using MAX in scalar subquery of where clause
 */
SELECT DISTINCT
    MAX(salary) AS SecondHighestSalary
FROM Employee
WHERE salary < (
    SELECT
        MAX(salary) AS maxSalary
    FROM Employee
);

/**
  4. Window function
 */
SELECT (
    SELECT
        salary
    FROM (
        SELECT
            salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
        FROM Employee
    ) AS salary_rank_table
    WHERE salary_rank = 2
    LIMIT 1
) AS SecondHighestSalary;