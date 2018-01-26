drop table if exists yuji_zout_count_charge_category;
create table yuji_zout_count_charge_category
as
select row_number() over(order by t1.name) as id, 
	t1.name,
	if(t2.charge_num is null, 0, t2.charge_num) as charge_num,
	if(t2.charge_users is null, 0, t2.charge_users) as charge_users,
	-- 时间（小时、年-月-日）
	substr(getdate(), 12, 2) as run_hour,
	substr(getdate(), 1, 10) as run_date,
	unix_timestamp() as run_time
from
(
	select 	r2.name 
	from 	yuji_together_charge as r1, 
			yuji_together_charge_class as r2 
	where	r1.cate_fid = r2.id 
	group by r2.name
) as t1
left join 
(	-- 关联记账类别表_charge_class和记账表_together_charge查询记账类别
	select 	tct.name, 
			count(distinct tc.charge_id) as charge_num,
			count(distinct tc.user_id) as charge_users
	from 	yuji_together_charge as tc,
			yuji_together_charge_class as tct
	where 	tc.cate_fid = tct.id 
		-- 过去一小时内
		and tc.add_time > (unix_timestamp()-3600) and tc.add_time < unix_timestamp()
	group by tct.name
) as t2
on t1.name = t2.name;

select * from yuji_zout_count_charge_category;
