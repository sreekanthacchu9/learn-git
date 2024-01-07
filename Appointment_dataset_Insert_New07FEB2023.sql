insert into emr_reports.appointment_dataset(
hospital_id,hosp_code,hosp_name,appt_date,appt_time,appointment_booked_time,appointment_booked_user_id,appointment_booked_role_id,patient_id,
patient_mrno,age_at_visited,age_by_days,gender,appt_Status,appt_id,case_sheet_master_id,tcm_cross,tcm_investigation_flag,
tcm_is_cross_opened,tcm_date,tcm_time,ta_check_in_time,ta_check_in_date,ta_checked_in_by,patient_category_id,category_name,
ta_appt_payment,visit_type_code,visit_type,visit_type_id,tpe_emergency_level,appt_doctor_id,doctor_Name,doc_short_code,dept_code,
dept_id,case_sheet_master_dept_id,td_id,dept_name,checkout_doctor,check_out_frontdesk,checkout_ta_doc_refraction_sent,
checkout_ta_no_diagnosis,ta_fd_checkout_time,checkout_ta_send_to_ivr,ta_grabi_advised,ta_doc_checkout_time,ta_medical_report_generated,
appt_type,ta_appt_status_id,status_appt_id,ta_appt_status,ta_waiting_hall_time,ta_get_patient_time,ta_workup_time,wrkup_time1,
wrkup_time2,ta_ready_for_consultant_time,ta_dilated_pl_time,ta_post_dilated_time,ta_dilated_time,ta_send_for_inv_time,
ta_lasik_status,ta_ocular_exa_saved_date,ta_ocular_exa_saved_time,wheel_chair_tag,diff_appt_time_checkin_time_mins,
diff_checkin_fd_checkout_mins,doc_chkout_time_mins,patient_trust_flag,date_first_seen,record_time,cs_optom_id,trl_optom_id,
trl_modified_date,wrkup_date_time,ready_consult_date_time,invs_create_dt_time,invs_suggest,iop_time,appt_log_date)
select ta.ta_hospital_id as hospital_id,ths.th_sap_code as hosp_code,ths.th_hospital_name as hosp_name,
ta.ta_appt_date as appt_date,ta.ta_appt_time as appt_time,
ta.ta_created_time as appointment_booked_time,
ta.ta_appt_given_by as appointment_booked_user_id,
ta.ta_appt_given_account as appointment_booked_role_id,
ta.ta_patient_id as patient_id,tp.tp_mrno as patient_mrno,
ROUND(DATEDIFF(ta.ta_appt_date, tp.tp_dob) / 365) AS age_at_visited,
DATEDIFF(ta.ta_appt_date, tp.tp_dob) as age_by_days,
tp.tp_gender as gender,
case when tcm.tcm_cs_id is not null then 'Completed' when tac.ta_cancel_id is not null then 'Cancelled' else 'Dropout' end as Appt_Status,
ta.ta_id as appt_id,tcm.tcm_cs_id as case_sheet_master_id,
tcm.tcm_cross,tcm.tcm_investigation_flag,
tcm.tcm_is_cross_opened,tcm.tcm_date,tcm.tcm_time,
taci.ta_check_in_time,taci.ta_check_in_date,taci.ta_checked_in_by,
taci.ta_category as patient_category_id,
CASE WHEN (taci.ta_category = 1) THEN 'NON_PAY' WHEN (taci.ta_category = 2) THEN 'GENERAL' 
WHEN (taci.ta_category = 3) THEN 'SUPPORTER' WHEN (taci.ta_category = 4) THEN 'SAVER' END AS category_name,
taci.ta_appt_payment,
tv.tavt_appt_type_short_code as visit_type_code,
tv.tavt_description as visit_type,ta.ta_visit_type as visit_type_id,
CASE tpe.tpe_emergency_level WHEN '1' THEN 'LEVEL 1 EMERGENCY' WHEN '2' THEN 'LEVEL 2 EMERGENCY' END AS tpe_emergency_level,
ta.ta_doc_id as appt_doctor_id,
CONCAT_WS(' ',td.tdoc_title,' ',td.tdoc_first_name,' ',td.tdoc_last_name)as Doctor_Name,
td.tdoc_short_code as doc_short_code,
tdept.td_short_code as dept_code,
ta.ta_dept_id as dept_id,tcm.tcm_dep_id as case_sheet_master_dept_id,tdept.td_id,tdept.td_dept_name as dept_name,
taco.ta_doctor as checkout_doctor,taco.ta_frontdesk as check_out_frontdesk,
taco.ta_doc_refraction_sent as checkout_ta_doc_refraction_sent,
taco.ta_no_diagnosis as checkout_ta_no_diagnosis,taco.ta_fd_checkout_time,taco.ta_send_to_ivr as checkout_ta_send_to_ivr,
taco.ta_grabi_advised,taco.ta_doc_checkout_time,taco.ta_medical_report_generated,
case when tecti_id is null then 'internal' else 'external' end as appt_type,
tast.ta_appt_status_id,tast.ta_appt_id as status_appt_id,tast.ta_appt_status,tast.ta_waiting_hall_time,tast.ta_get_patient_time,
tast.ta_workup_time,tch.tocs_modified_time as wrkup_time1,trl.tr_modified_time as wrkup_time2,
tast.ta_ready_for_consultant_time,tast.ta_dilated_pl_time,tast.ta_post_dilated_time,tast.ta_dilated_time,tast.ta_send_for_inv_time,tast.ta_lasik_status,
tast.ta_ocular_exa_saved_date,tast.ta_ocular_exa_saved_time,
if(tpwc.tpwc_id is not null,1,0) as wheel_chair_tag,
TIMESTAMPDIFF(MINUTE,CONCAT(ta.ta_appt_date,' ',ta.ta_appt_time),taci.ta_check_in_time) as diff_appt_time_checkin_time_mins,
TIMESTAMPDIFF(MINUTE,taci.ta_check_in_time,taco.ta_fd_checkout_time) AS diff_checkin_fd_checkout_mins,
TIMESTAMPDIFF(MINUTE,taci.ta_check_in_time,taco.ta_doc_checkout_time) AS doc_chkout_time_mins,
ead.patient_trust_flag,ead.appt_date_first_seen as date_first_seen,
(select min(tl.tcsl_record_time) from tbl_case_history_log tl where tl.tcsl_cs_id=tcm.tcm_cs_id and tcsl_cs_optom_id is not null order by 1 asc limit 1) as record_time,
(select tl1.tcsl_cs_optom_id from tbl_case_history_log tl1 where tl1.tcsl_cs_id=tcm.tcm_cs_id and tcsl_cs_optom_id is not null order by 1 asc limit 1) as cs_optom_id,
(select trl_optom_id from tbl_reviews_log tlg where tlg.trl_cs_id=tcm.tcm_cs_id and tlg.trl_optom_id > 0 order by 1 asc limit 1) as trl_optom_id,
(select min(tg.trl_modified_date) from tbl_reviews_log tg where tg.trl_cs_id=tcm.tcm_cs_id and tg.trl_optom_id > 0 order by 1 asc limit 1) as trl_modified_date,
(select wrkup_time.tcscct_date_time from tbl_cs_color_code_tracker wrkup_time where wrkup_time.tcscct_cs_id=tcm.tcm_cs_id
	and wrkup_time.tcscct_status_id=3 order by 1 asc limit 1) as wrkup_date_time,
(select redy_for_consult.tcscct_date_time from tbl_cs_color_code_tracker redy_for_consult where redy_for_consult.tcscct_cs_id=tcm.tcm_cs_id
	and redy_for_consult.tcscct_status_id=4 order by 1 asc limit 1) as ready_consult_date_time,
(select min(tphd_created_time) from tbl_photograph_diagnostics tpd where tpd.tphd_appt_id=ta.ta_id order by 1 asc limit 1) as invs_suggest_time,
 (select if(tphd_appt_id is not null,1,0) from tbl_photograph_diagnostics tpd where tpd.tphd_appt_id=ta.ta_id limit 1) as invs_suggest,
 (select tooc_modified_time from tbl_ocular_applanation_tonometry toat where toat.tooc_cs_id=tcm.tcm_cs_id order by 1 asc limit 1) as iop_time,
current_date
from tbl_appointment ta
join tbl_patient tp on ta.ta_patient_id=tp.tp_id
left join tbl_appointment_cancelled tac on ta.ta_id=tac.ta_cancel_id
left join tbl_case_sheet_master tcm on ta.ta_id=tcm.tcm_appt_id
JOIN tbl_appointment_visit_type tv ON ta.ta_visit_type = tv.tavt_id
JOIN tbl_doctors td ON td.tdoc_id = ta.ta_doc_id
JOIN tbl_departments tdept ON tdept.td_id = ta.ta_dept_id
LEFT JOIN tbl_pat_emergency tpe ON ta.ta_id = tpe.tpe_appt_id
LEFT JOIN tbl_appt_check_in taci on ta.ta_id=taci.ta_appt_id
LEFT JOIN tbl_appt_check_out taco on ta.ta_id=taco.ta_appt_id
left join tbl_external_converted_to_internal tecti on ta.ta_id=tecti.tecti_real_appt_id
left join tbl_appointment_status_time tast on ta.ta_id=tast.ta_appt_id
left join tbl_pat_wheel_chair tpwc on ta.ta_id=tpwc_appt_id
left join emr_appointment_dataset ead on ta.ta_id=ead.appt_id
join tbl_hospitals ths on ta.ta_hospital_id=ths.th_id
left join tbl_case_history tch on tcm.tcm_cs_id=tch.tocs_cs_id
left join tbl_reviews trl on tcm.tcm_cs_id=trl.tr_cs_id
left join emr_reports.appointment_dataset ad on ta.ta_id=ad.appt_id
#where ad.appt_id is null and ta.ta_appt_date between in_from_dt and in_to_dt
where ad.appt_id is null and ta.ta_appt_date between '2023-01-01' and '2023-01-31'
order by ta_appt_date asc,appt_time asc;