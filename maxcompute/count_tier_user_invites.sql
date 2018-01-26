DROP TABLE IF EXISTS yuji_operate_level_1;
CREATE TABLE yuji_operate_level_1
AS
-- 一级用户：最早拥有的圈子是自己创建的圈子
SELECT ROW_NUMBER() OVER (ORDER BY utr.user_id) AS id, utr.user_id, utr.invite_user_id, utr.create_time
FROM yuji_user_together_rel utr
WHERE utr.user_id = utr.invite_user_id
	AND utr.is_dummy = 0
	AND utr.id IN (
		SELECT t.min_id
		FROM (
			SELECT user_id, MIN(id) AS min_id
			FROM yuji_user_together_rel
			GROUP BY user_id
		) t
	);
SELECT * FROM yuji_operate_level_1;


DROP TABLE IF EXISTS yuji_operate_level_2;
CREATE TABLE yuji_operate_level_2
AS
-- 二级用户：最早拥有的圈子是一级用户创建的圈子
SELECT 	ROW_NUMBER() OVER (ORDER BY utr.user_id) AS id, 
		utr.user_id, 
	  	utr.invite_user_id, 
		utr.create_time
FROM yuji_user_together_rel utr
WHERE utr.user_id != utr.invite_user_id
	AND utr.is_dummy = 0
	AND utr.invite_user_id IN (
		SELECT user_id
		FROM yuji_operate_level_1
	)
	AND utr.id IN (
		SELECT t.min_id
		FROM (
			SELECT user_id, MIN(id) AS min_id
			FROM yuji_user_together_rel
			GROUP BY user_id
		) t
	);
SELECT * FROM yuji_operate_level_2;


DROP TABLE IF EXISTS yuji_operate_level_3;
CREATE TABLE yuji_operate_level_3
AS
-- 三级用户：最早拥有的圈子是二级用户创建的圈子
SELECT ROW_NUMBER() OVER (ORDER BY utr.user_id) AS id, utr.user_id, utr.invite_user_id, utr.create_time
FROM yuji_user_together_rel utr, yuji_operate_level_2 lvl2
WHERE utr.invite_user_id = lvl2.user_id
	AND utr.user_id != utr.invite_user_id
	AND utr.is_dummy = 0
	AND utr.id IN (
		SELECT t.min_id
		FROM (
			SELECT user_id, MIN(id) AS min_id
			FROM yuji_user_together_rel
			GROUP BY user_id
		) t
	);
SELECT * FROM yuji_operate_level_3;


DROP TABLE IF EXISTS yuji_zout_count_lv_users;
CREATE TABLE yuji_zout_count_lv_users
AS
SELECT ROW_NUMBER() OVER (ORDER BY res.count_lv2 DESC, 
		res.count_lv3 DESC) AS id, res.*
FROM (
	SELECT t.user_id, 
		   SUM(IF(t.lv2 IS NULL, 0, 1)) AS count_lv2, 
		   SUM(IF(t.lv3 IS NULL, 0, 1)) AS count_lv3, 
		   SUBSTR(getdate(), 12, 2) AS run_hour, 
		   SUBSTR(getdate(), 1, 10) AS run_date, 
		   unix_timestamp() AS run_ts
	FROM (
		SELECT l1.user_id, l2.user_id AS lv2, l3.user_id AS lv3
		FROM yuji_operate_level_1 l1
		FULL OUTER JOIN yuji_operate_level_2 l2
		ON l1.user_id = l2.invite_user_id
		FULL OUTER JOIN yuji_operate_level_3 l3
		ON l2.user_id = l3.invite_user_id
	) t
	GROUP BY t.user_id
) res;
SELECT * FROM yuji_zout_count_lv_users;
