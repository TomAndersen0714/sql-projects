-- 178. Rank Scores
-- https://leetcode.com/problems/rank-scores/
/*
Create table If Not Exists Scores (id int, score DECIMAL(3,2));
Truncate table Scores;
insert into Scores (id, score) values ('1', '3.5');
insert into Scores (id, score) values ('2', '3.65');
insert into Scores (id, score) values ('3', '4.0');
insert into Scores (id, score) values ('4', '3.85');
insert into Scores (id, score) values ('5', '4.0');
insert into Scores (id, score) values ('6', '3.65');
*/

/*
 dense_rank() window function
 */
SELECT
    score, d_rank AS `rank`
FROM (
    SELECT
        score, DENSE_RANK() OVER(ORDER BY score DESC) AS d_rank
    FROM Scores
) AS scores_rank
ORDER BY score DESC;