DELIMITER $$
create procedure insupd_bill_details( )
	begin
	declare lv_from_dt date;
	declare lv_to_dt date;
	declare lv_last_run_dt date;
	select last_run_dt into lv_last_run_dt
	from emr_reports.tbl_jobs_tables where job_name='insupd_bill_details' order by last_run_dt_time desc limit 1;
	 
 		if lv_last_run_dt=date_add(current_date, INTERVAL -1 DAY) then
 			begin
 				set lv_from_dt=date_add(current_date, INTERVAL -1 DAY);
 				set lv_to_dt=lv_from_dt;
 			end;
 		else
 			begin
 				set lv_from_dt=lv_last_run_dt;
 				set lv_to_dt=date_add(current_date, INTERVAL -1 DAY);
 			end;
 		end if;
 
 		if lv_from_dt='' or lv_from_dt is null then
 			begin
 				set lv_from_dt=date_add(current_date, INTERVAL -1 DAY);
 			end;
 		end if;
 
 		if lv_to_dt= '' or lv_to_dt is null then 
 			set lv_to_dt= lv_from_dt;
 		end if;
 
 		if lv_to_dt < lv_from_dt then
 			set lv_to_dt=lv_from_dt;    
 		end if;
     
 		SET SQL_SAFE_UPDATES = 0;
 		delete from emr_reports.bill_details where receipt_date between lv_from_dt and lv_to_dt;
 		SET SQL_SAFE_UPDATES = 1;
         
 		
         insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'INVS' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.tib_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.tphd_appt_id as appt_id,b.tphd_case_sheet_id as casesheet_id,
 		b.tphd_dept as invs_dept_id,
 		b.tphd_test_id as mast_id,b.tphd_test_code as mast_code,
 		a.tib_id as emr_bill_id,c.tibd_id as emr_bill_det_id,
 		a.tib_inv_id as emr_service_id,b.tphd_id as req_auto_id,
 		a.tib_amount as srvc_amt,null as room_rent,null as ga_amt,
 		a.tib_amount as bill_amt,
 		c.tibd_amount as receipt_amt,c.tibd_case_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.tibd_case_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.tibd_case_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		c.tibd_frontdesk as bill_user_id,
 		if (c.tibd_case_mode='COMP',a.tib_company_id,null) as comp_id,
 		if (c.tibd_case_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.tibd_case_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.tphd_doc_id as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tphd_opd_dept as req_opd_dept_id,
 		b.tphd_created_date as req_sugg_date,b.tphd_created_time as req_sugg_date_time,
 		a.tib_created_date as bill_date,a.tib_created_time as bill_date_time,
 		c.tibd_created_date as receipt_date,c.tibd_created_time as receipt_date_time,
 		current_date
 		from tbl_investigation_bill a
 		join tbl_investigation_bill_details c on a.tib_id=c.tibd_bill_id
 		join tbl_photograph_diagnostics b on a.tib_inv_id=b.tphd_id
 		left join tbl_frontdesk fd on c.tibd_frontdesk=fd.tf_id
 		left join tbl_companies comp on a.tib_company_id=comp.toc_id
 		join tbl_departments dept on b.tphd_opd_dept=dept.td_id
 		join tbl_doctors doc on tphd_doc_id=tdoc_id
 		join tbl_patient pat on a.tib_patient_id=pat.tp_id
 		join tbl_hospitals th on a.tib_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.tibd_id=bd.emr_bill_det_id and bd.bill_type='INVS' and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.tibd_created_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'INVS' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		ib.tib_id as emr_bill_id,null as emr_bill_det_id,
 		ib.tib_inv_id as emr_service_id,dis.tobd_id as req_auto_id,
 		ib.tib_amount as srvc_amt,null as room_rent,null as ga_amt,
 		ib.tib_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tphd_opd_dept as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		ib.tib_created_date as bill_date,ib.tib_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_investigation_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_investigation_bill ib on dis.tobd_investigation_id=ib.tib_inv_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_photograph_diagnostics b on dis.tobd_investigation_id=b.tphd_id
 		join tbl_departments dept on b.tphd_opd_dept=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='INVS' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.tobd_status=1 and dis.tobd_request_type='INV_DISCOUNT'
 		and dis.tobd_updated_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'INVS' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		ib.tib_id as emr_bill_id,null as emr_bill_det_id,
 		ib.tib_inv_id as emr_service_id,dis.tobd_id as req_auto_id,
 		ib.tib_amount as srvc_amt,null as room_rent,null as ga_amt,
 		ib.tib_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tphd_opd_dept as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		ib.tib_created_date as bill_date,ib.tib_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_investigation_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_investigation_bill ib on dis.tobd_investigation_id=ib.tib_inv_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_photograph_diagnostics b on dis.tobd_investigation_id=b.tphd_id
 		join tbl_departments dept on b.tphd_opd_dept=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='INVS' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.tobd_updated_date between lv_from_dt and lv_to_dt
 		and dis.tobd_status=1 and dis.tobd_request_type='INV_REFUND';        
         
         
         
         insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'OPD_CNSL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.top_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		a.top_appt_id as appt_id,null as casesheet_id,
 		b.ta_dept_id as appt_dept_id,
 		null as mast_id,null as mast_code,
 		a.top_id as emr_bill_id,a.top_id as emr_bill_det_id,
 		a.top_appt_id as emr_service_id,b.ta_id as req_auto_id,
 		a.top_total_amt as srvc_amt,null as room_rent,null as ga_amt,
 		a.top_total_amt as bill_amt,
 		a.top_total_paid as receipt_amt,a.top_case_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when a.top_case_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  a.top_case_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		a.top_fd_id as bill_user_id,
 		if (a.top_case_mode='COMP',a.top_company_id,null) as comp_id,
 		if (a.top_case_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (a.top_case_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.ta_doc_id as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.ta_dept_id as req_opd_dept_id,
 		date(b.ta_created_time) as req_sugg_date,b.ta_created_time as req_sugg_date_time,
 		a.top_created_date as bill_date,a.top_created_time as bill_date_time,
 		a.top_created_date as receipt_date,a.top_created_time as receipt_date_time,
 		current_date
 		from tbl_opd_bill a
 		join tbl_appointment b on a.top_appt_id=b.ta_id
 		left join tbl_frontdesk fd on a.top_fd_id=fd.tf_id
 		left join tbl_companies comp on a.top_company_id=comp.toc_id
 		join tbl_departments dept on b.ta_dept_id=dept.td_id
 		join tbl_doctors doc on b.ta_doc_id=tdoc_id
 		join tbl_patient pat on a.top_patient_id=pat.tp_id
 		join tbl_hospitals th on a.top_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on a.top_id=bd.emr_bill_det_id and bd.bill_type='OPD_CNSL' and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and a.top_created_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'OPD_CNSL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		dis.tobd_appt_id as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		ob.top_id as emr_bill_id,ob.top_id as emr_bill_det_id,
 		ob.top_appt_id as emr_service_id,dis.tobd_id as req_auto_id,
 		ob.top_total_amt as srvc_amt,null as room_rent,null as ga_amt,
 		ob.top_total_amt as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.ta_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		ob.top_created_date as bill_date,ob.top_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_opd_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_opd_bill ob on dis.tobd_appt_id=ob.top_appt_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_appointment b on dis.tobd_appt_id=b.ta_id
 		join tbl_departments dept on b.ta_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='OPD_CNSL' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.tobd_status=1 and dis.tobd_request_type='OPD_DISCOUNT'
 		and dis.tobd_updated_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'OPD_CNSL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		dis.tobd_appt_id as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		ob.top_id as emr_bill_id,ob.top_id as emr_bill_det_id,
 		ob.top_appt_id as emr_service_id,dis.tobd_id as req_auto_id,
 		ob.top_total_amt as srvc_amt,null as room_rent,null as ga_amt,
 		ob.top_total_amt as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.ta_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		ob.top_created_date as bill_date,ob.top_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_opd_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_opd_bill ob on dis.tobd_appt_id=ob.top_appt_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_appointment b on dis.tobd_appt_id=b.ta_id
 		join tbl_departments dept on b.ta_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='OPD_CNSL' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.tobd_status=1 and dis.tobd_request_type='OPD_REFUND'
 		and dis.tobd_updated_date between lv_from_dt and lv_to_dt;
 		
         
 		
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'CONTACT_LENS' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.tclb_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.tclr_appt_id as appt_id,b.tclr_case_sheet_id as casesheet_id,
 		b.tclr_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		a.tclb_id as emr_bill_id,c.tclbd_id as emr_bill_det_id,
 		a.tclb_request_id as emr_service_id,b.tclr_id as req_auto_id,
 		a.tclb_total_bill_amount as srvc_amt,null as room_rent,null as ga_amt,
 		a.tclb_total_bill_amount as bill_amt,
 		c.tclbd_amount as receipt_amt,c.tclbd_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.tclbd_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.tclbd_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		c.tclbd_generated_by as bill_user_id,
 		if (c.tclbd_mode='COMP',a.tclb_company,null) as comp_id,
 		if (c.tclbd_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.tclbd_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.tclr_requested_by as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tclr_dept_id as req_opd_dept_id,
 		b.tclr_requested_date as req_sugg_date,b.tclr_requested_time as req_sugg_date_time,
 		a.tclb_created_date as bill_date,a.tclb_created_time as bill_date_time,
 		c.tclbd_created_date as receipt_date,c.tclbd_created_time as receipt_date_time,
 		current_date
 		from tbl_contact_lens_bill a
 		join tbl_contact_lens_bill_details c on a.tclb_id=c.tclbd_bill_id
 		join tbl_contact_lens_requested b on a.tclb_request_id=b.tclr_id
 		left join tbl_frontdesk fd on c.tclbd_generated_by=fd.tf_id
 		left join tbl_companies comp on a.tclb_company=comp.toc_id
 		join tbl_departments dept on b.tclr_dept_id=dept.td_id
 		join tbl_doctors doc on b.tclr_requested_by=tdoc_id
 		join tbl_patient pat on a.tclb_patient_id=pat.tp_id
 		join tbl_hospitals th on a.tclb_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.tclbd_id=bd.emr_bill_det_id and bd.bill_type='CONTACT_LENS'
 		and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.tclbd_created_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'CONTACT_LENS' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.tclr_appt_id as appt_id,b.tclr_case_sheet_id as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		lb.tclb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tobd_contact_len_id as emr_service_id,dis.tobd_id as req_auto_id,
 		lb.tclb_total_bill_amount as srvc_amt,null as room_rent,null as ga_amt,
 		lb.tclb_total_bill_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tclr_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		lb.tclb_created_date as bill_date,lb.tclb_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_contact_len_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_contact_lens_bill lb on dis.tobd_contact_len_id=lb.tclb_request_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_contact_lens_requested b on dis.tobd_contact_len_id=b.tclr_id
 		join tbl_departments dept on b.tclr_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='CONTACT_LENS' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.tobd_status=1 and dis.tobd_request_type='CTLEN_DISCOUNT'
 		and dis.tobd_updated_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'CONTACT_LENS' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.tclr_appt_id as appt_id,b.tclr_case_sheet_id as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		lb.tclb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tobd_contact_len_id as emr_service_id,dis.tobd_id as req_auto_id,
 		lb.tclb_total_bill_amount as srvc_amt,null as room_rent,null as ga_amt,
 		lb.tclb_total_bill_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tclr_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		lb.tclb_created_date as bill_date,lb.tclb_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_contact_len_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_contact_lens_bill lb on dis.tobd_contact_len_id=lb.tclb_request_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_contact_lens_requested b on dis.tobd_contact_len_id=b.tclr_id
 		join tbl_departments dept on b.tclr_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='CONTACT_LENS' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.tobd_status=1 and dis.tobd_request_type='CTLEN_REFUND'
 		and dis.tobd_updated_date between lv_from_dt and lv_to_dt;            
 		
         
         
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'LVD_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.tlb_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.tldfb_appt_id as appt_id,b.tldfb_case_sheet_id as casesheet_id,
 		b.tldfb_dept_id as invs_dept_id,
 		null as mast_id,b.tldfb_code as mast_code,
 		a.tlb_id as emr_bill_id,c.tlbd_id as emr_bill_det_id,
 		a.tlb_lvd_id as emr_service_id,b.tldfb_id as req_auto_id,
 		a.tlb_total_billed_amount as srvc_amt,null as room_rent,null as ga_amt,
 		a.tlb_total_billed_amount as bill_amt,
 		c.tlbd_amount as receipt_amt,c.tlbd_cash_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.tlbd_cash_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.tlbd_cash_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		c.tlbd_frontdesk as bill_user_id,
 		if (c.tlbd_cash_mode='COMP',a.tlb_company_id,null) as comp_id,
 		if (c.tlbd_cash_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.tlbd_cash_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.tldfb_doc_id as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tldfb_dept_id as req_opd_dept_id,
 		b.tldfb_created_date as req_sugg_date,b.tldfb_created_time as req_sugg_date_time,
 		a.tlb_created_date as bill_date,a.tlb_created_time as bill_date_time,
 		c.tlbd_created_date as receipt_date,c.tlbd_created_time as receipt_date_time,
 		current_date
 		from tbl_lvd_bill a
 		join tbl_lvd_bill_details c on a.tlb_id=c.tlbd_bill_id
 		join tbl_lvd_devices_for_billing b on a.tlb_lvd_id=b.tldfb_id
 		left join tbl_frontdesk fd on c.tlbd_frontdesk=fd.tf_id
 		left join tbl_companies comp on a.tlb_company_id=comp.toc_id
 		join tbl_departments dept on b.tldfb_dept_id=dept.td_id
 		join tbl_doctors doc on b.tldfb_doc_id=tdoc_id
 		join tbl_patient pat on a.tlb_patient_id=pat.tp_id
 		join tbl_hospitals th on a.tlb_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.tlbd_id=bd.emr_bill_det_id and bd.bill_type='LVD_BILL'
 		and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.tlbd_created_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'LVD_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.tldfb_appt_id as appt_id,b.tldfb_case_sheet_id as casesheet_id,
 		b.tldfb_dept_id as invs_dept_id,
 		null as mast_id,b.tldfb_code as mast_code,
 		tb.tlb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tobd_lvd_id as emr_service_id,dis.tobd_id as req_auto_id,
 		tb.tlb_total_billed_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.tlb_total_billed_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tldfb_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		tb.tlb_created_date as bill_date,tb.tlb_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_lvd_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_lvd_bill tb on dis.tobd_lvd_id=tb.tlb_lvd_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_lvd_devices_for_billing b on dis.tobd_lvd_id=b.tldfb_id
 		join tbl_departments dept on b.tldfb_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='LVD_BILL' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.tobd_status=1 and dis.tobd_request_type='LVD_DISCOUNT'
 		and dis.tobd_updated_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'LVD_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.tldfb_appt_id as appt_id,b.tldfb_case_sheet_id as casesheet_id,
 		b.tldfb_dept_id as invs_dept_id,
 		null as mast_id,b.tldfb_code as mast_code,
 		tb.tlb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tobd_lvd_id as emr_service_id,dis.tobd_id as req_auto_id,
 		tb.tlb_total_billed_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.tlb_total_billed_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tldfb_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		tb.tlb_created_date as bill_date,tb.tlb_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_lvd_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_lvd_bill tb on dis.tobd_lvd_id=tb.tlb_lvd_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_lvd_devices_for_billing b on dis.tobd_lvd_id=b.tldfb_id
 		join tbl_departments dept on b.tldfb_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='LVD_BILL' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.tobd_status=1 and dis.tobd_request_type='LVD_REFUND'
 		and dis.tobd_updated_date between lv_from_dt and lv_to_dt;
         
         
         
         insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'REHAB_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.trb_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.trr_appt_id as appt_id,b.trr_case_sheet_id as casesheet_id,
 		b.trr_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		a.trb_id as emr_bill_id,c.trbd_id as emr_bill_det_id,
 		a.trb_request_id as emr_service_id,b.trr_id as req_auto_id,
 		a.trb_total_bill_amount as srvc_amt,null as room_rent,null as ga_amt,
 		a.trb_total_bill_amount as bill_amt,
 		c.trbd_amount as receipt_amt,c.trbd_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.trbd_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.trbd_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		c.trbd_generated_by as bill_user_id,
 		if (c.trbd_mode='COMP',a.trb_company,null) as comp_id,
 		if (c.trbd_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.trbd_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.trr_requested_by as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.trr_dept_id as req_opd_dept_id,
 		b.trr_requested_date as req_sugg_date,b.trr_requested_time as req_sugg_date_time,
 		a.trb_created_date as bill_date,a.trb_created_time as bill_date_time,
 		c.trbd_created_date as receipt_date,c.trbd_created_time as receipt_date_time,
 		current_date
 		from tbl_rehab_bill a
 		join tbl_rehab_bill_details c on a.trb_id=c.trbd_bill_id
 		join tbl_rehab_requested b on a.trb_request_id=b.trr_id
 		left join tbl_frontdesk fd on c.trbd_generated_by=fd.tf_id
 		left join tbl_companies comp on a.trb_company=comp.toc_id
 		join tbl_departments dept on b.trr_dept_id=dept.td_id
 		join tbl_doctors doc on b.trr_requested_by=doc.tdoc_id
 		join tbl_patient pat on a.trb_patient_id=pat.tp_id
 		join tbl_hospitals th on a.trb_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.trbd_id=bd.emr_bill_det_id and bd.bill_type='REHAB_BILL' and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.trbd_created_date between lv_from_dt and lv_to_dt;
         
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'REHAB_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.trr_appt_id as appt_id,b.trr_case_sheet_id as casesheet_id,
 		b.trr_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.trb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tobd_rehab_id as emr_service_id,dis.tobd_id as req_auto_id,
 		tb.trb_total_bill_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.trb_total_bill_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.trr_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		tb.trb_created_date as bill_date,tb.trb_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_rehab_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_rehab_bill tb on dis.tobd_rehab_id=tb.trb_request_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_rehab_requested b on dis.tobd_rehab_id=b.trr_id
 		join tbl_departments dept on b.trr_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='REHAB_BILL' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.tobd_status='1' and dis.tobd_request_type='REHAB_DISCOUNT'
 		and dis.tobd_updated_date between lv_from_dt and lv_to_dt;
         
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'REHAB_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.trr_appt_id as appt_id,b.trr_case_sheet_id as casesheet_id,
 		b.trr_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.trb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tobd_rehab_id as emr_service_id,dis.tobd_id as req_auto_id,
 		tb.trb_total_bill_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.trb_total_bill_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.trr_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		tb.trb_created_date as bill_date,tb.trb_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_rehab_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_rehab_bill tb on dis.tobd_rehab_id=tb.trb_request_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_rehab_requested b on dis.tobd_rehab_id=b.trr_id
 		join tbl_departments dept on b.trr_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='REHAB_BILL' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.tobd_status='1' and dis.tobd_request_type='REHAB_REFUND'
 		and dis.tobd_updated_date between lv_from_dt and lv_to_dt;
         
         
         
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'BIO_CHEM' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.ttb_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		d.tbr_dept_id as invs_dept_id,
 		b.tbrd_test_id as mast_id,null as mast_code,
 		a.ttb_id as emr_bill_id,c.ttbd_id as emr_bill_det_id,
 		a.ttb_test_id as emr_service_id,b.tbrd_id as req_auto_id,
 		a.ttb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		a.ttb_amount as bill_amt,
 		c.ttbd_amount as receipt_amt,c.ttbd_case_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.ttbd_case_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.ttbd_case_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		c.ttbd_frontdesk as bill_user_id,
 		if (c.ttbd_case_mode='COMP',a.ttb_company_id,null) as comp_id,
 		if (c.ttbd_case_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.ttbd_case_mode='COMP',comp.toc_sap_key,null) as company_code,
 		d.tbr_ophthalmologist as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,d.tbr_dept_id as req_opd_dept_id,
 		d.tbr_requested_date as req_sugg_date,concat(d.tbr_requested_date,' ',d.tbr_requested_time) as req_sugg_date_time,
 		a.ttb_created_date as bill_date,concat(a.ttb_created_date,' ',a.ttb_created_time) as bill_date_time,
 		c.ttbd_created_date as receipt_date,concat(c.ttbd_created_date,' ',c.ttbd_created_time) as receipt_date_time,
 		current_date
 		from tbl_tests_bill a
 		join tbl_tests_bill_details c on a.ttb_id=c.ttbd_bill_id
 		join tbl_bio_request_details b on a.ttb_test_id=b.tbrd_id
 		join tbl_bio_request d on b.tbrd_request_id=d.tbr_id
 		left join tbl_frontdesk fd on c.ttbd_frontdesk=fd.tf_id
 		left join tbl_companies comp on a.ttb_company_id=comp.toc_id
 		join tbl_departments dept on d.tbr_dept_id=dept.td_id
 		join tbl_doctors doc on d.tbr_ophthalmologist=tdoc_id
 		join tbl_patient pat on a.ttb_patient_id=pat.tp_id
 		join tbl_hospitals th on a.ttb_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.ttbd_id=bd.emr_bill_det_id and bd.bill_type='BIO_CHEM' and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.ttbd_created_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'BIO_CHEM' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.ttbd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		brd.tbrd_test_id as mast_id,null as mast_code,
 		tb.ttb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.ttbd_tests_for_bill_id as emr_service_id,dis.ttbd_id as req_auto_id,
 		tb.ttb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.ttb_amount as bill_amt,
 		dis.ttbd_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.ttbd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.ttbd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tbr_dept_id as req_opd_dept_id,
 		dis.ttbd_created_date as req_sugg_date,concat(dis.ttbd_created_date,' ',dis.ttbd_created_time) as req_sugg_date_time,
 		tb.ttb_created_date as bill_date,concat(tb.ttb_created_date,' ',tb.ttb_created_time) as bill_date_time,
 		dis.ttbd_updated_date as receipt_date,concat(dis.ttbd_updated_date,' ',dis.ttbd_updated_time) as receipt_date_time,
 		current_date
 		from tbl_tests_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.ttbd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.ttbd_consultant=doc.tdoc_id
 		left join tbl_tests_bill tb on dis.ttbd_tests_for_bill_id=tb.ttb_test_id
 		join tbl_patient pat on dis.ttbd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.ttbd_hospital_id=th.th_id
 		join tbl_bio_request_details brd on dis.ttbd_tests_for_bill_id=brd.tbrd_id
 		join tbl_bio_request b on brd.tbrd_request_id=b.tbr_id
 		join tbl_departments dept on b.tbr_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.ttbd_id=bd.req_auto_id and bd.bill_type='BIO_CHEM' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.ttbd_status=1 and dis.ttbd_request_type='BIOCHEMISTRY_DISCOUNT'
 		and dis.ttbd_updated_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'BIO_CHEM' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.ttbd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		brd.tbrd_test_id as mast_id,null as mast_code,
 		tb.ttb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.ttbd_tests_for_bill_id as emr_service_id,dis.ttbd_id as req_auto_id,
 		tb.ttb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.ttb_amount as bill_amt,
 		dis.ttbd_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.ttbd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.ttbd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tbr_dept_id as req_opd_dept_id,
 		dis.ttbd_created_date as req_sugg_date,concat(dis.ttbd_created_date,' ',dis.ttbd_created_time) as req_sugg_date_time,
 		tb.ttb_created_date as bill_date,concat(tb.ttb_created_date,' ',tb.ttb_created_time) as bill_date_time,
 		dis.ttbd_updated_date as receipt_date,concat(dis.ttbd_updated_date,' ',dis.ttbd_updated_time) as receipt_date_time,
 		current_date
 		from tbl_tests_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.ttbd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.ttbd_consultant=doc.tdoc_id
 		left join tbl_tests_bill tb on dis.ttbd_tests_for_bill_id=tb.ttb_test_id
 		join tbl_patient pat on dis.ttbd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.ttbd_hospital_id=th.th_id
 		join tbl_bio_request_details brd on dis.ttbd_tests_for_bill_id=brd.tbrd_id
 		join tbl_bio_request b on brd.tbrd_request_id=b.tbr_id
 		join tbl_departments dept on b.tbr_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.ttbd_id=bd.req_auto_id and bd.bill_type='BIO_CHEM' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.ttbd_status=1 and dis.ttbd_request_type='BIOCHEMISTRY_REFUND'
 		and dis.ttbd_updated_date between lv_from_dt and lv_to_dt;
         
         
         
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'DIET_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.tdb_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,b.tdfb_case_sheet_id as casesheet_id,
 		b.tdfb_referred_by_dep_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		a.tdb_id as emr_bill_id,c.tdbd_id as emr_bill_det_id,
 		a.tdb_for_bill_id as emr_service_id,b.tdfb_id as req_auto_id,
 		a.tdb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		a.tdb_amount as bill_amt,
 		c.tdbd_amount as receipt_amt,c.tdbd_case_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.tdbd_case_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.tdbd_case_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		c.tdbd_frontdesk as bill_user_id,
 		if (c.tdbd_case_mode='COMP',a.tdb_company_id,null) as comp_id,
 		if (c.tdbd_case_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.tdbd_case_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.tdfb_doc_id as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tdfb_referred_by_dep_id as req_opd_dept_id,
 		b.tdfb_created_date as req_sugg_date,concat(b.tdfb_created_date,' ',b.tdfb_created_time) as req_sugg_date_time,
 		a.tdb_created_date as bill_date,concat(a.tdb_created_date,' ',a.tdb_created_time) as bill_date_time,
 		c.tdbd_created_date as receipt_date,concat(c.tdbd_created_date,' ',c.tdbd_created_time) as receipt_date_time,
 		current_date
 		from tbl_dietician_bill a
 		join tbl_dietician_bill_details c on a.tdb_id=c.tdbd_bill_id
 		join tbl_dietician_for_bill b on a.tdb_for_bill_id=b.tdfb_id
 		left join tbl_frontdesk fd on c.tdbd_frontdesk=fd.tf_id
 		left join tbl_companies comp on a.tdb_company_id=comp.toc_id
 		join tbl_departments dept on b.tdfb_referred_by_dep_id=dept.td_id
 		join tbl_doctors doc on b.tdfb_doc_id=tdoc_id
 		join tbl_patient pat on a.tdb_patient_id=pat.tp_id
 		join tbl_hospitals th on a.tdb_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.tdbd_id=bd.emr_bill_det_id and bd.bill_type='DIET_BILL' and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.tdbd_created_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'DIET_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tdbd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,b.tdfb_case_sheet_id as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.tdb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tdbd_for_bill_id as emr_service_id,dis.tdbd_id as req_auto_id,
 		tb.tdb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.tdb_amount as bill_amt,
 		dis.tdbd_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tdbd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tdbd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tdfb_referred_by_dep_id as req_opd_dept_id,
 		dis.tdbd_created_date as req_sugg_date,concat(dis.tdbd_created_date,' ',dis.tdbd_created_time) as req_sugg_date_time,
 		tb.tdb_created_date as bill_date,concat(tb.tdb_created_date,' ',tb.tdb_created_time) as bill_date_time,
 		dis.tdbd_updated_date as receipt_date,concat(dis.tdbd_updated_date,' ',dis.tdbd_updated_time) as receipt_date_time,
 		current_date
 		from tbl_dietician_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tdbd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tdbd_consultant=doc.tdoc_id
 		left join tbl_dietician_bill tb on dis.tdbd_for_bill_id=tb.tdb_for_bill_id
 		join tbl_patient pat on dis.tdbd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tdbd_hospital_id=th.th_id
 		join tbl_dietician_for_bill b on dis.tdbd_for_bill_id=b.tdfb_id
 		join tbl_departments dept on b.tdfb_referred_by_dep_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tdbd_id=bd.req_auto_id and bd.bill_type='DIET_BILL' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.tdbd_status=1 and dis.tdbd_request_type='DIETICIAN_DISCOUNT'
 		and dis.tdbd_updated_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'DIET_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tdbd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,b.tdfb_case_sheet_id as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.tdb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tdbd_for_bill_id as emr_service_id,dis.tdbd_id as req_auto_id,
 		tb.tdb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.tdb_amount as bill_amt,
 		dis.tdbd_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tdbd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tdbd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tdfb_referred_by_dep_id as req_opd_dept_id,
 		dis.tdbd_created_date as req_sugg_date,concat(dis.tdbd_created_date,' ',dis.tdbd_created_time) as req_sugg_date_time,
 		tb.tdb_created_date as bill_date,concat(tb.tdb_created_date,' ',tb.tdb_created_time) as bill_date_time,
 		dis.tdbd_updated_date as receipt_date,concat(dis.tdbd_updated_date,' ',dis.tdbd_updated_time) as receipt_date_time,
 		current_date
 		from tbl_dietician_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tdbd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tdbd_consultant=doc.tdoc_id
 		left join tbl_dietician_bill tb on dis.tdbd_for_bill_id=tb.tdb_for_bill_id
 		join tbl_patient pat on dis.tdbd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tdbd_hospital_id=th.th_id
 		join tbl_dietician_for_bill b on dis.tdbd_for_bill_id=b.tdfb_id
 		join tbl_departments dept on b.tdfb_referred_by_dep_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tdbd_id=bd.req_auto_id and bd.bill_type='DIET_BILL' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.tdbd_status=1 and dis.tdbd_request_type='DIETICIAN_REFUND'
 		and dis.tdbd_updated_date between lv_from_dt and lv_to_dt;
         
         
         
         
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 
 		select 'PHYSICIAN' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.tpb_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		b.tpfb_referred_by_dep_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		a.tpb_id as emr_bill_id,c.tpbd_bill_id as emr_bill_det_id,
 		a.tpb_for_bill_id as emr_service_id,b.tpfb_id as req_auto_id,
 		a.tpb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		a.tpb_amount as bill_amt,
 		c.tpbd_amount as receipt_amt,c.tpbd_case_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.tpbd_case_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.tpbd_case_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		c.tpbd_frontdesk as bill_user_id,
 		if (c.tpbd_case_mode='COMP',a.tpb_company_id,null) as comp_id,
 		if (c.tpbd_case_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.tpbd_case_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.tpfb_physician_id as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tpfb_referred_by_dep_id as req_opd_dept_id,
 		b.tpfb_created_date as req_sugg_date,concat(b.tpfb_created_date,' ',b.tpfb_created_time) as req_sugg_date_time,
 		a.tpb_created_date as bill_date,concat(a.tpb_created_date,' ',a.tpb_created_time) as bill_date_time,
 		c.tpbd_created_date as receipt_date,concat(c.tpbd_created_date,' ',c.tpbd_created_time) as receipt_date_time,
 		current_date
 		from tbl_physician_bill a
 		join tbl_physician_bill_details c on a.tpb_id=c.tpbd_bill_id
 		join tbl_physician_for_bill b on a.tpb_for_bill_id=b.tpfb_id
 		join tbl_frontdesk fd on c.tpbd_frontdesk=fd.tf_id
 		left join tbl_companies comp on a.tpb_company_id=comp.toc_id
 		join tbl_departments dept on b.tpfb_referred_by_dep_id=dept.td_id
 		join tbl_doctors doc on b.tpfb_physician_id=doc.tdoc_id
 		join tbl_patient pat on a.tpb_patient_id=pat.tp_id
 		join tbl_hospitals th on a.tpb_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.tpbd_id=bd.emr_bill_det_id and bd.bill_type='PHYSICIAN'
 		and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.tpbd_created_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'PHYSICIAN' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tpbd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.tpb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tpbd_for_bill_id as emr_service_id,dis.tpbd_id as req_auto_id,
 		tb.tpb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.tpb_amount as bill_amt,
 		dis.tpbd_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tpbd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tpbd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tpfb_referred_by_dep_id as req_opd_dept_id,
 		dis.tpbd_created_date as req_sugg_date,concat(dis.tpbd_created_date,' ',dis.tpbd_created_time) as req_sugg_date_time,
 		tb.tpb_created_date as bill_date,concat(tb.tpb_created_date,' ',tb.tpb_created_time) as bill_date_time,
 		dis.tpbd_updated_date as receipt_date,concat(dis.tpbd_updated_date,' ',dis.tpbd_updated_time) as receipt_date_time,
 		current_date
 		from tbl_physician_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tpbd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tpbd_consultant=doc.tdoc_id
 		left join tbl_physician_bill tb on dis.tpbd_for_bill_id=tb.tpb_for_bill_id
 		join tbl_patient pat on dis.tpbd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tpbd_hospital_id=th.th_id
 		join tbl_physician_for_bill b on dis.tpbd_for_bill_id=b.tpfb_id
 		join tbl_departments dept on b.tpfb_referred_by_dep_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tpbd_id=bd.req_auto_id and bd.bill_type='PHYSICIAN' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.tpbd_status=1 and dis.tpbd_request_type='PHYSICIAN_DISCOUNT'
 		and dis.tpbd_updated_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'PHYSICIAN' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tpbd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.tpb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tpbd_for_bill_id as emr_service_id,dis.tpbd_id as req_auto_id,
 		tb.tpb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.tpb_amount as bill_amt,
 		dis.tpbd_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tpbd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tpbd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tpfb_referred_by_dep_id as req_opd_dept_id,
 		dis.tpbd_created_date as req_sugg_date,concat(dis.tpbd_created_date,' ',dis.tpbd_created_time) as req_sugg_date_time,
 		tb.tpb_created_date as bill_date,concat(tb.tpb_created_date,' ',tb.tpb_created_time) as bill_date_time,
 		dis.tpbd_updated_date as receipt_date,concat(dis.tpbd_updated_date,' ',dis.tpbd_updated_time) as receipt_date_time,
 		current_date
 		from tbl_physician_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tpbd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tpbd_consultant=doc.tdoc_id
 		left join tbl_physician_bill tb on dis.tpbd_for_bill_id=tb.tpb_for_bill_id
 		join tbl_patient pat on dis.tpbd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tpbd_hospital_id=th.th_id
 		join tbl_physician_for_bill b on dis.tpbd_for_bill_id=b.tpfb_id
 		join tbl_departments dept on b.tpfb_referred_by_dep_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tpbd_id=bd.req_auto_id and bd.bill_type='PHYSICIAN' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.tpbd_status=1 and dis.tpbd_request_type='PHYSICIAN_REFUND'
 		and dis.tpbd_updated_date between lv_from_dt and lv_to_dt;        
         
         
         
         insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'PAID_RX' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.tppb_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		a.tppb_appt_id as appt_id,a.tppb_casesheet_id as casesheet_id,
 		a.tppb_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		a.tppb_id as emr_bill_id,c.tppbd_id as emr_bill_det_id,
 		a.tppb_presc_id as emr_service_id,b.tpres_id as req_auto_id,
 		a.tppb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		a.tppb_amount as bill_amt,
 		c.tppbd_amount as receipt_amt,c.tppbd_case_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.tppbd_case_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.tppbd_case_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		c.tppbd_frontdesk_id as bill_user_id,
 		if (c.tppbd_case_mode='COMP',a.tppb_company_id,null) as comp_id,
 		if (c.tppbd_case_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.tppbd_case_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.tpres_doc_id as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,a.tppb_dept_id as req_opd_dept_id,
 		b.tpres_created_date as req_sugg_date,b.tpres_created_time as req_sugg_date_time,
 		a.tppb_created_date as bill_date,concat(a.tppb_created_date,' ',a.tppb_created_time) as bill_date_time,
 		c.tppbd_created_date as receipt_date,concat(c.tppbd_created_date,' ',c.tppbd_created_time) as receipt_date_time,
 		current_date
 		from tbl_paid_prescription_bill a
 		join tbl_paid_prescription_bill_details c on a.tppb_id=c.tppbd_bill_id
 		join tbl_prescription b on a.tppb_presc_id=b.tpres_id
 		left join tbl_frontdesk fd on c.tppbd_frontdesk_id=fd.tf_id
 		left join tbl_companies comp on a.tppb_company_id=comp.toc_id
 		join tbl_departments dept on a.tppb_dept_id=dept.td_id
 		join tbl_doctors doc on b.tpres_doc_id=doc.tdoc_id
 		join tbl_patient pat on a.tppb_patient_id=pat.tp_id
 		join tbl_hospitals th on a.tppb_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.tppbd_id=bd.emr_bill_det_id and bd.bill_type='PAID_RX' and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.tppbd_created_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'PAID_RX' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tppbdr_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		tb.tppb_appt_id as appt_id,tb.tppb_casesheet_id as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.tppb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tppbdr_presc_id as emr_service_id,dis.tppbdr_id as req_auto_id,
 		tb.tppb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.tppb_amount as bill_amt,
 		dis.tppbdr_auth_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tppbdr_request_sent_id as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tppbdr_auth_doc_id as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,tb.tppb_dept_id as req_opd_dept_id,
 		dis.tppbdr_created_date as req_sugg_date,concat(dis.tppbdr_created_date,' ',dis.tppbdr_created_time) as req_sugg_date_time,
 		tb.tppb_created_date as bill_date,concat(tb.tppb_created_date,' ',tb.tppb_created_time) as bill_date_time,
 		dis.tppbdr_updated_date as receipt_date,concat(dis.tppbdr_updated_date,' ',dis.tppbdr_updated_time) as receipt_date_time,
 		current_date
 		from tbl_paid_prescription_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tppbdr_request_sent_id=fd.tf_id
 		join tbl_doctors doc on dis.tppbdr_auth_doc_id=doc.tdoc_id
 		left join tbl_paid_prescription_bill tb on dis.tppbdr_presc_id=tb.tppb_presc_id
 		join tbl_patient pat on dis.tppbdr_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tppbdr_hosp_id=th.th_id
 		join tbl_prescription b on dis.tppbdr_presc_id=b.tpres_id
 		left join tbl_departments dept on tb.tppb_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tppbdr_id=bd.req_auto_id and bd.bill_type='PAID_RX' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.tppbdr_status='1' and dis.tppbdr_request_type='PRESC_DISCOUNT'
 		and dis.tppbdr_updated_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'PAID_RX' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.tppb_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		a.tppb_appt_id as appt_id,a.tppb_casesheet_id as casesheet_id,
 		a.tppb_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		a.tppb_id as emr_bill_id,c.tppbd_id as emr_bill_det_id,
 		a.tppb_presc_id as emr_service_id,b.tpres_id as req_auto_id,
 		a.tppb_amount as srvc_amt,null as room_rent,null as ga_amt,
 		a.tppb_amount as bill_amt,
 		c.tppbd_amount as receipt_amt,c.tppbd_case_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.tppbd_case_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.tppbd_case_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		c.tppbd_frontdesk_id as bill_user_id,
 		if (c.tppbd_case_mode='COMP',a.tppb_company_id,null) as comp_id,
 		if (c.tppbd_case_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.tppbd_case_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.tpres_doc_id as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,a.tppb_dept_id as req_opd_dept_id,
 		b.tpres_created_date as req_sugg_date,b.tpres_created_time as req_sugg_date_time,
 		a.tppb_created_date as bill_date,concat(a.tppb_created_date,' ',a.tppb_created_time) as bill_date_time,
 		c.tppbd_created_date as receipt_date,concat(c.tppbd_created_date,' ',c.tppbd_created_time) as receipt_date_time,
 		current_date
 		from tbl_paid_prescription_bill a
 		join tbl_paid_prescription_bill_details c on a.tppb_id=c.tppbd_bill_id
 		join tbl_prescription b on a.tppb_presc_id=b.tpres_id
 		left join tbl_frontdesk fd on c.tppbd_frontdesk_id=fd.tf_id
 		left join tbl_companies comp on a.tppb_company_id=comp.toc_id
 		join tbl_departments dept on a.tppb_dept_id=dept.td_id
 		join tbl_doctors doc on b.tpres_doc_id=doc.tdoc_id
 		join tbl_patient pat on a.tppb_patient_id=pat.tp_id
 		join tbl_hospitals th on a.tppb_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.tppbd_id=bd.emr_bill_det_id and bd.bill_type='PAID_RX' and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.tppbd_created_date between lv_from_dt and lv_to_dt;
         
         
         
         insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'PROCEDURE' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.topb_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.toop_appt_id as appt_id,b.toop_case_sheet_id as casesheet_id,
 		b.toop_dept_id as operation_dept_id,
 		null as mast_id,null as mast_code,
 		a.topb_id as emr_bill_id,c.topbd_id as emr_bill_det_id,
 		a.topb_operation_id as emr_service_id,b.toop_id as req_auto_id,
 		a.topb_amount as srvc_amt,a.topb_room_rent as room_rent,a.topb_ga_amt as ga_amt,
 		(a.topb_amount+a.topb_room_rent+a.topb_ga_amt) as bill_amt,
 		c.topbd_amount as receipt_amt,c.topbd_cash_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.topbd_cash_mode in ('CASH','DD','CC','ON') then 'RECEIPT' 
 		when  c.topbd_cash_mode='COMP' then 'COMPANY' else null end) as paymode_type,
 		'COUNSELOR' as bill_user_type,
 		concat_ws(' ',tc.tc_first_name,tc.tc_last_name) as bill_user_name,
 		c.topbd_counselor as bill_user_id,
 		if (c.topbd_cash_mode='COMP',a.topb_company_id,null) as comp_id,
 		if (c.topbd_cash_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.topbd_cash_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.toop_doc_id as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.toop_dept_id as req_opd_dept_id,
 		b.toop_created_date as req_sugg_date,b.toop_created_time as req_sugg_date_time,
 		a.topb_created_date as bill_date,a.topb_created_time as bill_date_time,
 		c.topbd_created_date as receipt_date,c.topbd_created_time as receipt_date_time,
 		current_date
 		from tbl_operation_bill a
 		join tbl_operation_bill_details c on a.topb_id=c.topbd_bill_id
 		join tbl_operation_or_procedure b on a.topb_operation_id=b.toop_id
 		left join tbl_counselor tc on c.topbd_counselor=tc.tc_id
 		left join tbl_companies comp on a.topb_company_id=comp.toc_id
 		join tbl_departments dept on b.toop_dept_id=dept.td_id
 		join tbl_doctors doc on b.toop_doc_id=doc.tdoc_id
 		join tbl_patient pat on a.topb_patient_id=pat.tp_id
 		join tbl_hospitals th on a.topb_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.topbd_id=bd.emr_bill_det_id and bd.bill_type='PROCEDURE' and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.topbd_created_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'PROCEDURE' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		ob.topb_id as emr_bill_id,null as emr_bill_det_id,
 		ob.topb_operation_id as emr_service_id,dis.tobd_id as req_auto_id,
 		ob.topb_amount as srvc_amt,ob.topb_room_rent as room_rent,ob.topb_ga_amt as ga_amt,
 		(ob.topb_amount+ob.topb_room_rent+ob.topb_ga_amt) as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'COUNSELOR' as bill_user_type,
 		concat_ws(' ',tc.tc_first_name,tc.tc_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.toop_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		ob.topb_created_date as bill_date,ob.topb_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_operation_bill_discount_refund dis
 		left join tbl_counselor tc on dis.tobd_sent_by=tc.tc_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_operation_bill ob on dis.tobd_operation_id=ob.topb_operation_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_operation_or_procedure b on dis.tobd_operation_id=b.toop_id
 		join tbl_departments dept on b.toop_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='PROCEDURE' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.tobd_updated_date between lv_from_dt and lv_to_dt
 		and dis.tobd_status=1 and dis.tobd_request_type='DISCOUNT';
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'PROCEDURE' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		ob.topb_id as emr_bill_id,null as emr_bill_det_id,
 		ob.topb_operation_id as emr_service_id,dis.tobd_id as req_auto_id,
 		ob.topb_amount as srvc_amt,ob.topb_room_rent as room_rent,ob.topb_ga_amt as ga_amt,
 		(ob.topb_amount+ob.topb_room_rent+ob.topb_ga_amt) as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'COUNSELOR' as bill_user_type,
 		concat_ws(' ',tc.tc_first_name,tc.tc_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.toop_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		ob.topb_created_date as bill_date,ob.topb_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_operation_bill_discount_refund dis
 		left join tbl_counselor tc on dis.tobd_sent_by=tc.tc_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_operation_bill ob on dis.tobd_operation_id=ob.topb_operation_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_operation_or_procedure b on dis.tobd_operation_id=b.toop_id
 		join tbl_departments dept on b.toop_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='PROCEDURE' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.tobd_updated_date between lv_from_dt and lv_to_dt
 		and dis.tobd_status=1 and dis.tobd_request_type='REFUND';
         
         
                 
         insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'REHAB_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.trb_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.trr_appt_id as appt_id,b.trr_case_sheet_id as casesheet_id,
 		b.trr_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		a.trb_id as emr_bill_id,c.trbd_id as emr_bill_det_id,
 		a.trb_request_id as emr_service_id,b.trr_id as req_auto_id,
 		a.trb_total_bill_amount as srvc_amt,null as room_rent,null as ga_amt,
 		a.trb_total_bill_amount as bill_amt,
 		c.trbd_amount as receipt_amt,c.trbd_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.trbd_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.trbd_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		c.trbd_generated_by as bill_user_id,
 		if (c.trbd_mode='COMP',a.trb_company,null) as comp_id,
 		if (c.trbd_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.trbd_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.trr_requested_by as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.trr_dept_id as req_opd_dept_id,
 		b.trr_requested_date as req_sugg_date,b.trr_requested_time as req_sugg_date_time,
 		a.trb_created_date as bill_date,a.trb_created_time as bill_date_time,
 		c.trbd_created_date as receipt_date,c.trbd_created_time as receipt_date_time,
 		current_date
 		from tbl_rehab_bill a
 		join tbl_rehab_bill_details c on a.trb_id=c.trbd_bill_id
 		join tbl_rehab_requested b on a.trb_request_id=b.trr_id
 		left join tbl_frontdesk fd on c.trbd_generated_by=fd.tf_id
 		left join tbl_companies comp on a.trb_company=comp.toc_id
 		join tbl_departments dept on b.trr_dept_id=dept.td_id
 		join tbl_doctors doc on b.trr_requested_by=doc.tdoc_id
 		join tbl_patient pat on a.trb_patient_id=pat.tp_id
 		join tbl_hospitals th on a.trb_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.trbd_id=bd.emr_bill_det_id and bd.bill_type='REHAB_BILL' and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.trbd_created_date between lv_from_dt and lv_to_dt;
         
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'REHAB_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.trr_appt_id as appt_id,b.trr_case_sheet_id as casesheet_id,
 		b.trr_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.trb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tobd_rehab_id as emr_service_id,dis.tobd_id as req_auto_id,
 		tb.trb_total_bill_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.trb_total_bill_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.trr_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		tb.trb_created_date as bill_date,tb.trb_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_rehab_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_rehab_bill tb on dis.tobd_rehab_id=tb.trb_request_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_rehab_requested b on dis.tobd_rehab_id=b.trr_id
 		join tbl_departments dept on b.trr_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='REHAB_BILL' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.tobd_status='1' and dis.tobd_request_type='REHAB_DISCOUNT'
 		and dis.tobd_updated_date between lv_from_dt and lv_to_dt;
         
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'REHAB_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.trr_appt_id as appt_id,b.trr_case_sheet_id as casesheet_id,
 		b.trr_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.trb_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tobd_rehab_id as emr_service_id,dis.tobd_id as req_auto_id,
 		tb.trb_total_bill_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.trb_total_bill_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.trr_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		tb.trb_created_date as bill_date,tb.trb_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_rehab_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_rehab_bill tb on dis.tobd_rehab_id=tb.trb_request_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_rehab_requested b on dis.tobd_rehab_id=b.trr_id
 		join tbl_departments dept on b.trr_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='REHAB_BILL' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.tobd_status='1' and dis.tobd_request_type='REHAB_REFUND'
 		and dis.tobd_updated_date between lv_from_dt and lv_to_dt;
         
         
          
         insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'MINOR_PROCEDURE' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.tmob_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.tmpc_appt_id as appt_id,b.tmpc_casesheet_id as casesheet_id,
 		b.tmpc_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		a.tmob_id as emr_bill_id,c.tmobd_id as emr_bill_det_id,
 		a.tmob_operation_id as emr_service_id,b.tmpc_case_id as req_auto_id,
 		a.tmob_amount as srvc_amt,a.tmob_charges as room_rent,null as ga_amt,
 		(a.tmob_amount+a.tmob_charges) as bill_amt,
 		c.tmobd_amount as receipt_amt,c.tmobd_cash_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.tmobd_cash_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.tmobd_cash_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',tc.tc_first_name,tc.tc_last_name) as bill_user_name,
 		c.tmobd_counselor as bill_user_id,
 		if (c.tmobd_cash_mode='COMP',a.tmob_company_id,null) as comp_id,
 		if (c.tmobd_cash_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.tmobd_cash_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.tmpc_doc_id as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tmpc_dept_id as req_opd_dept_id,
 		b.tmpc_advised_date as req_sugg_date,concat(b.tmpc_advised_date,' ',b.tmpc_advised_time) as req_sugg_date_time,
 		a.tmob_created_date as bill_date,a.tmob_created_time as bill_date_time,
 		c.tmobd_created_date as receipt_date,c.tmobd_created_time as receipt_date_time,
 		current_date
 		from tbl_minor_operation_bill a
 		join tbl_minor_operation_bill_details c on a.tmob_id=c.tmobd_bill_id
 		join tbl_minor_procedure_cases b on a.tmob_operation_id=b.tmpc_case_id
 		left join tbl_counselor tc on c.tmobd_counselor=tc.tc_id
 		left join tbl_companies comp on a.tmob_company_id=comp.toc_id
 		join tbl_departments dept on b.tmpc_dept_id=dept.td_id
 		join tbl_doctors doc on b.tmpc_doc_id=doc.tdoc_id
 		join tbl_patient pat on a.tmob_patient_id=pat.tp_id
 		join tbl_hospitals th on a.tmob_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.tmobd_id=bd.emr_bill_det_id and bd.bill_type='MINOR_PROCEDURE' and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.tmobd_created_date between lv_from_dt and lv_to_dt;
         
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'MINOR_PROCEDURE' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tmobdr_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.tmpc_appt_id as appt_id,b.tmpc_casesheet_id as casesheet_id,
 		b.tmpc_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.tmob_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tmobdr_case_id as emr_service_id,dis.tmobdr_id as req_auto_id,
 		tb.tmob_amount as srvc_amt,tb.tmob_charges as room_rent,null as ga_amt,
 		(tb.tmob_amount+tb.tmob_charges) as bill_amt,
 		dis.tmobdr_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',tc.tc_first_name,tc.tc_last_name) as bill_user_name,
 		dis.tmobdr_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tmobdr_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tmpc_dept_id as req_opd_dept_id,
 		dis.tmobdr_created_date as req_sugg_date,dis.tmobdr_created_time as req_sugg_date_time,
 		tb.tmob_created_date as bill_date,tb.tmob_created_time as bill_date_time,
 		dis.tmobdr_updated_date as receipt_date,dis.tmobdr_updated_time as receipt_date_time,
 		current_date
 		from tbl_minor_operation_bill_discount_refund dis
 		join tbl_counselor tc on dis.tmobdr_sent_by=tc.tc_id
 		join tbl_doctors doc on dis.tmobdr_consultant=doc.tdoc_id
 		left join tbl_minor_operation_bill tb on dis.tmobdr_case_id=tb.tmob_operation_id
 		join tbl_patient pat on dis.tmobdr_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tmobdr_hospital_id=th.th_id
 		join tbl_minor_procedure_cases b on dis.tmobdr_case_id=b.tmpc_case_id
 		join tbl_departments dept on b.tmpc_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tmobdr_id=bd.req_auto_id and bd.bill_type='MINOR_PROCEDURE' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.tmobdr_status='1' and dis.tmobdr_request_type='MINOR_DISCOUNT'
 		and dis.tmobdr_updated_date between lv_from_dt and lv_to_dt;
         
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'MINOR_PROCEDURE' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tmobdr_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.tmpc_appt_id as appt_id,b.tmpc_casesheet_id as casesheet_id,
 		b.tmpc_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.tmob_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tmobdr_case_id as emr_service_id,dis.tmobdr_id as req_auto_id,
 		tb.tmob_amount as srvc_amt,tb.tmob_charges as room_rent,null as ga_amt,
 		(tb.tmob_amount+tb.tmob_charges) as bill_amt,
 		dis.tmobdr_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',tc.tc_first_name,tc.tc_last_name) as bill_user_name,
 		dis.tmobdr_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tmobdr_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.tmpc_dept_id as req_opd_dept_id,
 		dis.tmobdr_created_date as req_sugg_date,dis.tmobdr_created_time as req_sugg_date_time,
 		tb.tmob_created_date as bill_date,tb.tmob_created_time as bill_date_time,
 		dis.tmobdr_updated_date as receipt_date,dis.tmobdr_updated_time as receipt_date_time,
 		current_date
 		from tbl_minor_operation_bill_discount_refund dis
 		join tbl_counselor tc on dis.tmobdr_sent_by=tc.tc_id
 		join tbl_doctors doc on dis.tmobdr_consultant=doc.tdoc_id
 		left join tbl_minor_operation_bill tb on dis.tmobdr_case_id=tb.tmob_operation_id
 		join tbl_patient pat on dis.tmobdr_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tmobdr_hospital_id=th.th_id
 		join tbl_minor_procedure_cases b on dis.tmobdr_case_id=b.tmpc_case_id
 		join tbl_departments dept on b.tmpc_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tmobdr_id=bd.req_auto_id and bd.bill_type='MINOR_PROCEDURE' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.tmobdr_status='1' and dis.tmobdr_request_type='MINOR_REFUND'
 		and dis.tmobdr_updated_date between lv_from_dt and lv_to_dt;
 		
         
         
         insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 
 		select 'IMC' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.tib_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		b.toop_appt_id as appt_id,b.toop_case_sheet_id as casesheet_id,
 		b.toop_dept_id as invs_dept_id,
 		null as mast_id,null as mast_code,
 		a.tib_id as emr_bill_id,c.tibd_id as emr_bill_det_id,
 		a.tib_imc_id as emr_service_id,b.toop_id as req_auto_id,
 		a.tib_amount as srvc_amt,a.tib_per_day_price as room_rent,null as ga_amt,
 		(a.tib_amount+a.tib_per_day_price) as bill_amt,
 		c.tibd_amount as receipt_amt,c.tibd_case_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.tibd_case_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.tibd_case_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'COUNSELOR' as bill_user_type,
 		concat_ws(' ',tc.tc_first_name,tc.tc_last_name) as bill_user_name,
 		c.tibd_counselor as bill_user_id,
 		if (c.tibd_case_mode='COMP',a.tib_company_id,null) as comp_id,
 		if (c.tibd_case_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.tibd_case_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.toop_doc_id as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.toop_dept_id as req_opd_dept_id,
 		b.toop_created_date as req_sugg_date,b.toop_created_time as req_sugg_date_time,
 		a.tib_created_date as bill_date,a.tib_created_time as bill_date_time,
 		c.tibd_created_date as receipt_date,c.tibd_created_time as receipt_date_time,
 		current_date
 		from tbl_imc_bill a
 		join tbl_imc_bill_details c on a.tib_id=c.tibd_bill_id
 		join tbl_imc b on a.tib_imc_id=b.toop_id
 		left join tbl_counselor tc on c.tibd_counselor=tc.tc_id
 		left join tbl_companies comp on a.tib_company_id=comp.toc_id
 		join tbl_departments dept on b.toop_dept_id=dept.td_id
 		join tbl_doctors doc on b.toop_doc_id=doc.tdoc_id
 		join tbl_patient pat on a.tib_patient_id=pat.tp_id
 		join tbl_hospitals th on a.tib_hospital_id=th.th_id
 		left join emr_reports.bill_details bd on c.tibd_id=bd.emr_bill_det_id and bd.bill_type='IMC'
 		and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.tibd_created_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'IMC' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		ib.tib_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tobd_imc_id as emr_service_id,dis.tobd_id as req_auto_id,
 		ib.tib_amount as srvc_amt,null as room_rent,null as ga_amt,
 		ib.tib_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.toop_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		ib.tib_created_date as bill_date,ib.tib_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_imc_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_imc_bill ib on dis.tobd_imc_id=ib.tib_imc_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_imc b on dis.tobd_imc_id=b.toop_id
 		join tbl_departments dept on b.toop_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='IMC'
 		where bd.req_auto_id is null and dis.tobd_updated_date between lv_from_dt and lv_to_dt
 		and dis.tobd_status=1 and dis.tobd_request_type='IMC_DISCOUNT';
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'IMC' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.tobd_created_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		null as invs_dept_id,
 		null as mast_id,null as mast_code,
 		ib.tib_id as emr_bill_id,null as emr_bill_det_id,
 		dis.tobd_imc_id as emr_service_id,dis.tobd_id as req_auto_id,
 		ib.tib_amount as srvc_amt,null as room_rent,null as ga_amt,
 		ib.tib_amount as bill_amt,
 		dis.tobd_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.tobd_sent_by as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.tobd_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,b.toop_dept_id as req_opd_dept_id,
 		dis.tobd_created_date as req_sugg_date,dis.tobd_created_time as req_sugg_date_time,
 		ib.tib_created_date as bill_date,ib.tib_created_time as bill_date_time,
 		dis.tobd_updated_date as receipt_date,dis.tobd_updated_time as receipt_date_time,
 		current_date
 		from tbl_imc_bill_discount_refund dis
 		join tbl_frontdesk fd on dis.tobd_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.tobd_consultant=doc.tdoc_id
 		left join tbl_imc_bill ib on dis.tobd_imc_id=ib.tib_imc_id
 		join tbl_patient pat on dis.tobd_patient_id=pat.tp_id
 		join tbl_hospitals th on dis.tobd_hospital_id=th.th_id
 		join tbl_imc b on dis.tobd_imc_id=b.toop_id
 		join tbl_departments dept on b.toop_dept_id=dept.td_id
 		left join emr_reports.bill_details bd on dis.tobd_id=bd.req_auto_id and bd.bill_type='IMC'
 		where bd.req_auto_id is null and dis.tobd_updated_date between lv_from_dt and lv_to_dt
 		and dis.tobd_status=1 and dis.tobd_request_type='IMC_REFUND';
         
         
         
         insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'OPD_GENERIC' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(a.bill_create_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		8 as invs_dept_id,
 		null as mast_id,null as mast_code,
 		a.transaction_id as emr_bill_id,c.id as emr_bill_det_id,
 		a.request_id as emr_service_id,b.request_id as req_auto_id,
 		a.total_amount as srvc_amt,null as room_rent,null as ga_amt,
 		a.total_amount as bill_amt,
 		c.amount as receipt_amt,c.case_mode as pay_mode,'RECEIPT' as receipt_type,
 		(case when c.case_mode in ('CASH','DD','CC','ON') then 'RECEIPT'
 		when  c.case_mode='COMP' then 'COMPANY' else NULL end) as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		c.frontdesk_id as bill_user_id,
 		if (c.case_mode='COMP',a.company_id,null) as comp_id,
 		if (c.case_mode='COMP',comp.toc_company_name,null) as company_name,
 		if (c.case_mode='COMP',comp.toc_sap_key,null) as company_code,
 		b.request_user_id as req_sugg_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,8 as req_opd_dept_id,
 		b.requested_date as req_sugg_date,concat(b.requested_date,' ',b.requested_time) as req_sugg_date_time,
 		a.bill_create_date as bill_date,concat(a.bill_create_date,' ',a.bill_create_time) as bill_date_time,
 		c.created_date as receipt_date,c.created_time as receipt_date_time,
 		current_date
 		from opd_service_bill a
 		join opd_service_bill_details c on a.transaction_id=c.transaction_id
 		join opd_service_request b on a.request_id=b.request_id
 		left join tbl_frontdesk fd on c.frontdesk_id=fd.tf_id
 		left join tbl_companies comp on a.company_id=comp.toc_id
 		join tbl_departments dept on 8=dept.td_id
 		join tbl_doctors doc on b.request_user_id=doc.tdoc_id
 		join tbl_patient pat on b.patient_id=pat.tp_id
 		join tbl_hospitals th on a.hos_code=th.th_sap_code
 		left join emr_reports.bill_details bd on c.id=bd.emr_bill_det_id and bd.bill_type='OPD_GENERIC' and bd.receipt_type='RECEIPT'
 		where bd.emr_bill_det_id is null and c.created_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'OPD_GENERIC' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.osbdr_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		8 as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.transaction_id as emr_bill_id,null as emr_bill_det_id,
 		dis.osbdr_request_id as emr_service_id,dis.osbdr_id as req_auto_id,
 		tb.total_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.total_amount as bill_amt,
 		dis.osbdr_discount_amt as receipt_amt,null as pay_mode,'DISCOUNT' as receipt_type,
 		'DISCOUNT' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.osbdr_request_id as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.osbdr_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,8 as req_opd_dept_id,
 		dis.osbdr_created_date as req_sugg_date,dis.osbdr_created_time as req_sugg_date_time,
 		tb.bill_create_date as bill_date,concat(tb.bill_create_date,' ',tb.bill_create_time) as bill_date_time,
 		dis.osbdr_updated_date as receipt_date,concat(dis.osbdr_updated_date,' ',dis.osbdr_updated_time) as receipt_date_time,
 		current_date
 		from opd_service_bill_discount_refund dis
 		join opd_service_request b on dis.osbdr_request_id=b.request_id
 		join tbl_frontdesk fd on dis.osbdr_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.osbdr_consultant=doc.tdoc_id
 		left join opd_service_bill tb on dis.osbdr_request_id=tb.request_id
 		join tbl_patient pat on b.patient_id=pat.tp_id
 		join tbl_hospitals th on dis.osbdr_hospital_id=th.th_id
 		join tbl_departments dept on 8=dept.td_id
 		left join emr_reports.bill_details bd on dis.osbdr_id=bd.req_auto_id and bd.bill_type='OPD_GENERIC' and bd.receipt_type='DISCOUNT'
 		where bd.req_auto_id is null and dis.osbdr_status='1' and dis.osbdr_request_type='PHY_DISCOUNT'
 		and dis.osbdr_updated_date between lv_from_dt and lv_to_dt;
 
 		insert into emr_reports.bill_details(
 		bill_type,hosp_code,hosp_id,mrno,patient_id,patient_name,age,dob,gender,
 		pat_category,patient_cateogry,appt_id,casesheet_id,invs_dept_id,mast_id,mast_code,
 		emr_bill_id,emr_bill_det_id,emr_service_id,req_auto_id,srvc_amt,room_rent,ga_amt,
 		bill_amt,receipt_amt,pay_mode,receipt_type,paymode_type,bill_user_type,bill_user_name,
 		bill_user_id,comp_id,company_name,company_code,req_sugg_doc_id,consultant_id,consultant_name,
 		doc_short_code,opd_department,opd_dept_id,req_opd_dept_id,req_sugg_date,req_sugg_date_time,
 		bill_date,bill_date_time,receipt_date,receipt_date_time,run_dt)
 		select 'OPD_GENERIC' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,pat.tp_mrno as mrno,pat.tp_id as patient_id,
 		concat(pat.tp_first_name,' ',pat.tp_last_name) as patient_name,
 		round(datediff(dis.osbdr_updated_date,pat.tp_dob)/365) as age,
 		pat.tp_dob as dob,if(pat.tp_gender=1,'M','F') as gender,
 		pat.tp_category as pat_category,
 		case when pat.tp_category=1 then 'NON-PAY' when pat.tp_category=2 then 'GENERAL' when pat.tp_category=3 then 'SUPPORT'
 		when pat.tp_category=4 then 'SIGHT-SAVER' end as patient_cateogry,
 		null as appt_id,null as casesheet_id,
 		8 as invs_dept_id,
 		null as mast_id,null as mast_code,
 		tb.transaction_id as emr_bill_id,null as emr_bill_det_id,
 		dis.osbdr_request_id as emr_service_id,dis.osbdr_id as req_auto_id,
 		tb.total_amount as srvc_amt,null as room_rent,null as ga_amt,
 		tb.total_amount as bill_amt,
 		dis.osbdr_discount_amt as receipt_amt,null as pay_mode,'REFUND' as receipt_type,
 		'REFUND' as paymode_type,
 		'FRONT_DESK' as bill_user_type,
 		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
 		dis.osbdr_request_id as bill_user_id,
 		null as comp_id,
 		null as company_name,
 		null as company_code,
 		dis.osbdr_consultant as req_doc_id,doc.tdoc_id as consultant_id,
 		concat(doc.tdoc_first_name,' ',doc.tdoc_last_name) as consultant_name,
 		doc.tdoc_short_code as doc_short_code,
 		dept.td_dept_name as opd_department,dept.td_id as opd_dept_id,8 as req_opd_dept_id,
 		dis.osbdr_created_date as req_sugg_date,dis.osbdr_created_time as req_sugg_date_time,
 		tb.bill_create_date as bill_date,concat(tb.bill_create_date,' ',tb.bill_create_time) as bill_date_time,
 		dis.osbdr_updated_date as receipt_date,concat(dis.osbdr_updated_date,' ',dis.osbdr_updated_time) as receipt_date_time,
 		current_date
 		from opd_service_bill_discount_refund dis
 		join opd_service_request b on dis.osbdr_request_id=b.request_id
 		join tbl_frontdesk fd on dis.osbdr_sent_by=fd.tf_id
 		join tbl_doctors doc on dis.osbdr_consultant=doc.tdoc_id
 		left join opd_service_bill tb on dis.osbdr_request_id=tb.request_id
 		join tbl_patient pat on b.patient_id=pat.tp_id
 		join tbl_hospitals th on dis.osbdr_hospital_id=th.th_id
 		join tbl_departments dept on 8=dept.td_id
 		left join emr_reports.bill_details bd on dis.osbdr_id=bd.req_auto_id and bd.bill_type='OPD_GENERIC' and bd.receipt_type='REFUND'
 		where bd.req_auto_id is null and dis.osbdr_status='1' and dis.osbdr_request_type='PHY_REFUND'
 		and dis.osbdr_updated_date between lv_from_dt and lv_to_dt;
         
 
 insert into emr_reports.tbl_jobs_tables (tablename,job_name,table_description,last_run_dt,last_run_time)
 values ('bill_details','insupd_bill_details',
 'all bills data inserted in the table',current_date,current_time);
 end