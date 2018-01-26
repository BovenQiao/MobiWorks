drop table if exists yuji_zout_count_quanzhu_creates_invites;
create table yuji_zout_count_quanzhu_creates_invites as 
-- 按create_user_id创建人分组，统计该创建人过去一小时内，创建的圈子数、邀请的新用户数 --（暂弃）创建人参与的至少有一笔账单的圈子数
select 	
	row_number() over(order by t1.create_user_id) as id,
	t.create_user_id, 
	if(t1.created_quanzi is null, 0, t1.created_quanzi) as created_quanzi, 
	if(t3.invited_users is null, 0, t3.invited_users) as invited_users,
--	if(t4.charged_quanzi_num is null, 0, t4.charged_quanzi_num) as charged_quanzi,
	-- 时间（小时、年-月-日）
	substr(getdate(), 12, 2) as run_hour,
	substr(getdate(), 1, 10) as run_date,
	unix_timestamp() as run_time
from 
(
	select create_user_id from yuji_user_together group by create_user_id
) as t
left join
(		-- 过去一小时创建圈子的圈主id
		select create_user_id, count(distinct account_id) as created_quanzi 
		from yuji_user_together 
		where is_delete=0 
			-- 过去一小时
			and create_time > (unix_timestamp()-3600) and create_time < unix_timestamp()
		group by create_user_id 
) as t1
on t.create_user_id = t1.create_user_id
left join 
(	-- 邀请的新用户数
	select 	utr.invite_user_id, count(distinct utr.user_id) as invited_users 
	from 	yuji_user_together as ut, 
			yuji_user_together_rel as utr, 
			yuji_user_info_index as ui 
	where 	ut.create_user_id=utr.invite_user_id and utr.user_id=ui.user_id 
		-- 非虚拟、圈子创建时间早于用户注册时间
		and utr.is_dummy=0 and ut.create_time < ui.reg_time 
		-- 过去一小时之内
		and ui.reg_time > (unix_timestamp()-3600) and ui.reg_time < unix_timestamp()
	group by utr.invite_user_id 
) as t3 
on t1.create_user_id = t3.invite_user_id;
--left join 
--(	-- 已生产账单的圈子数
--	select 	ut.create_user_id,
--			count(distinct tuc.account_id) as charged_quanzi_num
--	from 	yuji_user_together as ut,
--			yuji_together_user_charge as tuc
--	where 	ut.account_id = tuc.account_id
--	group by ut.create_user_id
--) as t4 
--on t1.create_user_id = t4.create_user_id;

select * from yuji_zout_count_quanzhu_creates_invites;
