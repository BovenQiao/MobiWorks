drop table if exists yuji_zout_count_channel_xcx_to_app;
create table yuji_zout_count_channel_xcx_to_app as 
-- 回流到APP的统计,分渠道
select	row_number() over(order by res1.reg_from) as id,
		res1.reg_from,
		if(res2.chanel_users is null, 0, res2.chanel_users) as chanel_users,
		if(res2.sess_users is null, 0, res2.sess_users) as sess_users,
		-- 时间（小时、年-月-日）
		substr(getdate(), 12, 2) as run_hour,
		substr(getdate(), 1, 10) as run_date,
		unix_timestamp() as run_time
from
(		-- 查出预记的用户及其渠道
		select 	uinfo.reg_from
		from 	yuji_user_together_rel as rel, yuji_user_info_index as uinfo
		where 	rel.user_id = uinfo.user_id 
			-- 非虚拟、注册来源非空
			and rel.is_dummy=0 and uinfo.reg_from != ''
		group by uinfo.reg_from 
) as res1
left join
(
	select 	res.reg_from, 
			count(distinct res.uinfo_uid) as chanel_users, 
			count(distinct res.sess_uid) as sess_users
	from
	(	-- 查出关联session表后，device_id不为空的用户
		select t1.user_id as uinfo_uid, t2.user_id as sess_uid, t1.reg_from
		from 
		( 	-- 查出预记的用户及其渠道
			select 	rel.user_id, uinfo.reg_from
			from 	yuji_user_together_rel as rel, yuji_user_info_index as uinfo
			where 	rel.user_id = uinfo.user_id 
				-- 非虚拟、注册来源非空
				and rel.is_dummy=0 and uinfo.reg_from != ''
				-- 注册时间在过去一小时内
				and uinfo.reg_time > (unix_timestamp() -3600) and uinfo.reg_time < unix_timestamp()
			group by rel.user_id, uinfo.reg_from 
		) as t1
		left join 
		(	-- 查出device_id不为空的视为APP用户
			select	user_id
			from 	yuji_user_app_session 
			where	device_id != ''
			group by user_id
		) as t2
		on t1.user_id = t2.user_id
	) as res
	group by res.reg_from
) as res2
on res1.reg_from = res2.reg_from;

select * from yuji_zout_count_channel_xcx_to_app;
