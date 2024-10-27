-- 180. Consecutive Numbers
-- https://leetcode.com/problems/consecutive-numbers/
/*
Create table If Not Exists Logs (id int, num int);
Truncate table Logs;
insert into Logs (id, num) values ('1', '1');
insert into Logs (id, num) values ('2', '1');
insert into Logs (id, num) values ('3', '1');
insert into Logs (id, num) values ('4', '2');
insert into Logs (id, num) values ('5', '1');
insert into Logs (id, num) values ('6', '2');
insert into Logs (id, num) values ('7', '2');
*/

/*
 1. JOIN three times
 */
SELECT
    t1_t2_t3.num AS ConsecutiveNums
FROM (
    SELECT
        t1_2.t1_id,
        t1_2.num,
        t1_2.t2_id,
        t3.id AS t3_id
    FROM (
        SELECT
            t1.id AS t1_id,
            t1.num,
            t2.id AS t2_id
        FROM
            Logs AS t1
                LEFT JOIN Logs AS t2
                ON t1.num = t2.num AND t1.id = t2.id + 1
    ) AS t1_2
        LEFT JOIN Logs AS t3
            ON t1_2.num = t3.num AND t1_2.t2_id = t3.id + 1
) AS t1_t2_t3
WHERE t3_id IS NOT NULL;

/**
  2. Window function LEAD
 */
SELECT DISTINCT
    l0 AS ConsecutiveNums
FROM (
    SELECT
        id, num AS l0,
        LEAD(num, 1) over (order by id) AS l1,
        LEAD(num, 2) over (order by id) AS l2
    FROM Logs
) AS tmp
WHERE l0=l1 AND l1=l2;

/*
 3. Window function row_number
 */
SELECT DISTINCT
    num AS ConsecutiveNums
FROM (
    SELECT
        num,
        r_num - p_r_num AS block_num
    FROM (
        SELECT
            num,
            ROW_NUMBER() over (order by id) AS r_num,
            ROW_NUMBER() over (partition by num order by id) AS p_r_num
        FROM Logs
    ) AS block_num_tbl
) AS tmp
GROUP BY num, block_num
HAVING COUNT(1) >= 3;
