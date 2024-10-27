-- 181. Employees Earning More Than Their Managers
-- https://leetcode.com/problems/employees-earning-more-than-their-managers/
/*
Create table If Not Exists Employee (id int, name varchar(255), salary int, managerId int);
Truncate table Employee;
insert into Employee (id, name, salary, managerId) values ('1', 'Joe', '70000', '3');
insert into Employee (id, name, salary, managerId) values ('2', 'Henry', '80000', '4');
insert into Employee (id, name, salary, managerId) values ('3', 'Sam', '60000', null);
insert into Employee (id, name, salary, managerId) values ('4', 'Max', '90000', null);
*/

/*
 1. SELF JOIN
 */
SELECT
    t1.name AS Employee
FROM Employee AS t1
LEFT JOIN Employee AS t2
ON t1.managerId = t2.id
WHERE t1.salary > t2.salary;
