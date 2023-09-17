-- LeetCode 176 https://leetcode.com/problems/second-highest-salary/
/*
Create table If Not Exists Employee (id int, salary int);
Truncate table Employee;
insert into Employee (id, salary) values ('1', '100');
insert into Employee (id, salary) values ('2', '200');
insert into Employee (id, salary) values ('3', '300');
*/

/**
  1. Using window function
 */


/**
  2. Using order by and limit
 */
SELECT
    salary AS SecondHighestSalary
FROM Employee
ORDER BY salary DESC
LIMIT 1 offset 1;