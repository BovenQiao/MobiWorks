drop table if exists yuji_zout_count_user_creates_invites;
create table yuji_zout_count_user_creates_invites as
-- 根据用户分组，统计过去一小时内创建圈子数、加入圈子数、记账笔数、邀请新用户数
select 	row_number() over(order by t.user_id) as id, 
	t.user_id, 
	uii.reg_from,
	if(t1.created_quanzi is null, 0, t1.created_quanzi) as created_quanzi,
	if(t2.joined_quanzi is null, 0, t2.joined_quanzi) as joined_quanzi,
	if(t3.charge_num is null, 0, t3.charge_num) as charge_num,
	if(t4.invited_users is null, 0, t4.invited_users) as invited_users,
	-- 时间（小时、年-月-日）
	substr(getdate(), 12, 2) as run_hour,
	substr(getdate(), 1, 10) as run_date,
	unix_timestamp() as run_time
from
(
	select user_id from yuji_user_together_rel group by user_id
) as t
left join 
(	-- 创建圈子个数
	select 	utr.user_id, count(distinct utr.account_id) as created_quanzi
	from 	yuji_user_together_rel as utr,
			yuji_user_together as ut
	where 	utr.account_id = ut.account_id 
		-- 用户id不等于邀请人id，非虚拟
		and utr.user_id=utr.invite_user_id and utr.invite_user_id!=0 and ut.is_delete=0
		-- 过去一小时之内
		and ut.create_time > (unix_timestamp()-3600) and ut.create_time < unix_timestamp()
	group by utr.user_id
) as t1 
on t.user_id = t1.user_id
left join
(	-- 参与的圈子个数
	select 	utr.user_id, count(distinct utr.account_id) as joined_quanzi 
	from 	yuji_user_together as ut,
			yuji_user_together_rel as utr
	where 	ut.account_id=utr.account_id 
		-- 非虚拟、没删除的
		and utr.is_dummy=0 and ut.is_delete=0
		-- 过去一小时之内被邀请
		and utr.create_time > (unix_timestamp()-3600) and utr.create_time < unix_timestamp()
	group by utr.user_id 
) as t2
on t.user_id = t2.user_id
left join
(	-- 记账次数
	select 	utr.user_id, count(distinct tc.charge_id) as charge_num
	from 	yuji_user_together_rel as utr,
			yuji_together_charge as tc
	where 	utr.user_id = tc.user_id 
		-- 没删除的
		and tc.is_delete=0
	  	-- 过去一小时之内
		and tc.charge_time > (unix_timestamp()-3600) and tc.charge_time < unix_timestamp()
	group by utr.user_id
) as t3
on t.user_id = t3.user_id
left join 
(	-- 邀请的新用户数
	select utr.invite_user_id, ui.reg_from, count(distinct utr.user_id) as invited_users
	from 	yuji_user_together_rel as utr, 
			yuji_user_info_index as ui 
	where 	utr.user_id = ui.user_id 
		and utr.invite_user_id!=utr.user_id and utr.invite_user_id!=0
		and ui.reg_time > (unix_timestamp()-3600) and ui.reg_time < unix_timestamp()
		and utr.id in (
			-- 最早邀请的用户，过滤不同邀请人邀请同一个人的情况
			select t.min_id from (	
				select 	user_id, min(id) as min_id
				from 	yuji_user_together_rel 
				group by user_id  
			) as t
		) 
	group by utr.invite_user_id, ui.reg_from
) as t4 
on t.user_id = t4.invite_user_id
-- 为了关联出注册来源
left join yuji_user_info_index as uii
on t.user_id = uii.user_id
;

select * from yuji_zout_count_user_creates_invites;
