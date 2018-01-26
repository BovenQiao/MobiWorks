drop table if exists yuji_zout_count_class_quanzi_users;
create table yuji_zout_count_class_quanzi_users 
as
-- 不同类型圈子（班级、团建、聚会、旅游）的量级（圈子个数及总参与人数）增长速度。
-- 不同类型圈子之间，圈子使用频率（日均记账笔数）与使用人数（圈子人数）特点（按小时增量统计，不支持日均记账和使用人数）
select row_number() over(order by cls.id) as id,
	cls.id as class_id,
	cls.name as class_name,
	if(t.quanzi_num is null, 0, t.quanzi_num) as quanzi_num,
	if(t.quanzhu_num is null, 0, t.quanzhu_num) as quanzhu_num,
	if(t.quanzi_users is null, 0, t.quanzi_users) as quanzi_users,
	-- 时间（小时、年-月-日）
	substr(getdate(), 12, 2) as run_hour,
	substr(getdate(), 1, 10) as run_date,
	unix_timestamp() as run_time
from 
	yuji_user_together_class as cls
left join
(
	select 
		tc.id as cls_id,
		count(distinct ut.account_id) as quanzi_num, 
		count(distinct ut.create_user_id) as quanzhu_num,
		count(distinct utr.user_id) as quanzi_users
	from yuji_user_together as ut,
		yuji_user_together_rel as utr,
		yuji_user_together_class as tc
	where 	ut.account_id=utr.account_id and ut.cate_class_id = tc.id 
		-- 过去一小时创建的圈子
		and ut.create_time > (unix_timestamp()-3600) and ut.create_time < unix_timestamp()
		and utr.is_dummy=0
	group by tc.id
) as t
on cls.id = t.cls_id;

select * from yuji_zout_count_class_quanzi_users;
