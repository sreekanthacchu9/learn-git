drop procedure if exists insupd_company_bill_details;
DELIMITER $$
create procedure insupd_company_bill_details( )
begin
declare lv_from_dt date;	
declare lv_to_dt date;
declare lv_last_run_dt date;
select last_run_dt into lv_last_run_dt
from emr_reports.tbl_jobs_tables where job_name='insupd_company_bill_details' order by last_run_dt_time desc limit 1;
                
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
		delete from emr_reports.company_bill_details where receipt_date between lv_from_dt and lv_to_dt;
		SET SQL_SAFE_UPDATES = 1;
        
		/*Investigation Company Bills Start*/
		drop temporary table if exists tmp_comp_invs_bill;
		create temporary table if not exists tmp_comp_invs_bill
		select tibd_bill_id as emr_bill_id,tibd_id as emr_bill_det_id,tibd_created_date as receipt_date,
		a.tibd_case_mode,'FRONT_DESK' as bill_user_type,
		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
		a.tibd_frontdesk as bill_user_id
		from tbl_investigation_bill_details a
		left join tbl_frontdesk fd on a.tibd_frontdesk=fd.tf_id
		where a.tibd_case_mode='COMP' and tibd_created_date between lv_from_dt and lv_to_dt
		group by tibd_bill_id;

		create index ix_emr_bill_id on tmp_comp_invs_bill(emr_bill_id);
		create index ix_emr_bill_det_id on tmp_comp_invs_bill(emr_bill_det_id);


		insert into emr_reports.company_bill_details
		(
		bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
		bill_amt,paid_amt,company_amt,dis_amt,
		bill_user_type,bill_user_name,bill_user_id,
		bill_date,receipt_date,run_dt
		)
		select 'INVS' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
		a.tib_id as emr_bill_id,c.emr_bill_det_id,
		if (c.emr_bill_det_id is not null,a.tib_company_id,null) as comp_id,
		if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
		if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
		a.tib_amount as bill_amt,sum(if(b.tibd_amount is not null,b.tibd_amount,0)) as paid_amt,
		(a.tib_amount-if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0))-
		sum(if(b.tibd_amount is not null,b.tibd_amount,0)) as company_amt,
		if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0) as dis_amt,
		c.bill_user_type,c.bill_user_name,c.bill_user_id,
		a.tib_created_date as bill_date,c.receipt_date,current_date
		from tbl_investigation_bill a
		join tbl_investigation_bill_details b on a.tib_id=b.tibd_bill_id
		join tmp_comp_invs_bill c on a.tib_id=c.emr_bill_id
		left join tbl_investigation_bill_discount_refund dis on a.tib_inv_id=dis.tobd_investigation_id
		and dis.tobd_status=1 and dis.tobd_request_type='INV_DISCOUNT'
		left join tbl_companies comp on a.tib_company_id=comp.toc_id
		join tbl_hospitals th on a.tib_hospital_id=th.th_id
		left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
		where cb.emr_bill_det_id is null and a.tib_company_id > 0 
		group by a.tib_id order by tibd_bill_id asc;
        
        /*Investigation Company Bills End*/
        
		/*OPD Consultation Company Bills Start*/
		drop temporary table if exists tmp_comp_opd_bill;
		create temporary table if not exists tmp_comp_opd_bill
		select a.top_id as emr_bill_id,a.top_id as emr_bill_det_id,a.top_created_date as receipt_date,
		'FRONT_DESK' as bill_user_type,
		concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
		a.top_fd_id as bill_user_id
		from tbl_opd_bill a
		left join tbl_frontdesk fd on a.top_fd_id=fd.tf_id
		where a.top_case_mode='COMP' and a.top_created_date between lv_from_dt and lv_to_dt
		group by a.top_id;

		insert into emr_reports.company_bill_details
		(
		bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
		bill_amt,paid_amt,company_amt,dis_amt,bill_user_type,bill_user_name,bill_user_id,bill_date,receipt_date,run_dt
		)
		select 'OPD_CNSL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
		a.top_id as emr_bill_id,c.emr_bill_det_id,
		if (c.emr_bill_det_id is not null,a.top_company_id,null) as comp_id,
		if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
		if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
		a.top_total_amt as bill_amt,
		a.top_total_paid as paid_amt,
		(a.top_total_amt-if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0)-
		a.top_total_paid) as company_amt,
		if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0) as dis_amt,
		c.bill_user_type,c.bill_user_name,c.bill_user_id,
		a.top_created_date as bill_date,c.receipt_date,current_date
		from tbl_opd_bill a
		join tmp_comp_opd_bill c on a.top_id=c.emr_bill_id
		left join tbl_opd_bill_discount_refund dis on a.top_appt_id=dis.tobd_appt_id
		and dis.tobd_status=1 and dis.tobd_request_type='OPD_DISCOUNT'
		left join tbl_companies comp on a.top_company_id=comp.toc_id
		join tbl_hospitals th on a.top_hospital_id=th.th_id
		left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
		where cb.emr_bill_det_id is null and a.top_company_id > 0 group by a.top_id;
        /*OPD Consultation Company Bills End*/
        
			drop temporary table if exists tmp_comp_contactlens_bill;
			create temporary table if not exists tmp_comp_contactlens_bill
			select a.tclbd_bill_id as emr_bill_id,a.tclbd_id as emr_bill_det_id,a.tclbd_created_date as receipt_date,
			'FRONT_DESK' as bill_user_type,
			concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
			a.tclbd_generated_by as bill_user_id
			from tbl_contact_lens_bill_details a
			left join tbl_frontdesk fd on a.tclbd_generated_by=fd.tf_id
			where a.tclbd_mode='COMP' and a.tclbd_created_date between lv_from_dt and lv_to_dt
			group by a.tclbd_id;
            
			insert into emr_reports.company_bill_details
			(
			bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
			bill_amt,paid_amt,company_amt,dis_amt,bill_user_type,bill_user_name,bill_user_id,bill_date,receipt_date,run_dt
			)
			select 'CONTACT_LENS' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
			a.tclb_id as emr_bill_id,c.emr_bill_det_id,
			if (c.emr_bill_det_id is not null,a.tclb_company,null) as comp_id,
			if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
			if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
			a.tclb_total_bill_amount as bill_amt,
			sum(if(b.tclbd_amount is not null,b.tclbd_amount,0)) as paid_amt,
			(a.tclb_total_bill_amount-if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0))-
			sum(if(b.tclbd_amount is not null,b.tclbd_amount,0)) as company_amt,
			if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0) as dis_amt,
			c.bill_user_type,c.bill_user_name,c.bill_user_id,
			a.tclb_created_date as bill_date,c.receipt_date,current_date
			from tbl_contact_lens_bill a
			join tbl_contact_lens_bill_details b on a.tclb_id=b.tclbd_bill_id
			join tmp_comp_contactlens_bill c on a.tclb_id=c.emr_bill_id
			left join tbl_contact_len_bill_discount_refund dis on a.tclb_request_id=dis.tobd_contact_len_id
			and dis.tobd_status=1 and dis.tobd_request_type='CTLEN_DISCOUNT'
			left join tbl_companies comp on a.tclb_company=comp.toc_id
			join tbl_hospitals th on a.tclb_hospital_id=th.th_id
			left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
			where cb.emr_bill_det_id is null and a.tclb_company > 0 
			group by a.tclb_id;
			/*Contact Lens Company Bills End*/
            
			/*LVD Company Bills Start*/                
			drop temporary table if exists tmp_comp_lvd_bill;
			create temporary table if not exists tmp_comp_lvd_bill
			select a.tlbd_bill_id as emr_bill_id,a.tlbd_id as emr_bill_det_id,a.tlbd_created_date as receipt_date,
			'FRONT_DESK' as bill_user_type,
			concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
			a.tlbd_frontdesk as bill_user_id
			from tbl_lvd_bill_details a
			left join tbl_frontdesk fd on a.tlbd_frontdesk=fd.tf_id
			where a.tlbd_cash_mode='COMP' and a.tlbd_created_date between lv_from_dt and lv_to_dt
			group by a.tlbd_id;

			insert into emr_reports.company_bill_details
			(
			bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
			bill_amt,paid_amt,company_amt,dis_amt,
			bill_user_type,bill_user_name,bill_user_id,
			bill_date,receipt_date,run_dt
			)
			select 'LVD_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
			a.tlb_id as emr_bill_id,c.emr_bill_det_id,
			if (c.emr_bill_det_id is not null,a.tlb_company_id,null) as comp_id,
			if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
			if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
			a.tlb_total_billed_amount as bill_amt,
			sum(if(b.tlbd_amount is not null,b.tlbd_amount,0)) as paid_amt,
			(a.tlb_total_billed_amount-if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0))-
			sum(if(b.tlbd_amount is not null,b.tlbd_amount,0)) as company_amt,
			if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0) as dis_amt,
			c.bill_user_type,c.bill_user_name,c.bill_user_id,
			a.tlb_created_date as bill_date,c.receipt_date,current_date
			from tbl_lvd_bill a
			join tbl_lvd_bill_details b on a.tlb_id=b.tlbd_bill_id
			join tmp_comp_lvd_bill c on a.tlb_id=c.emr_bill_id
			left join tbl_lvd_bill_discount_refund dis on a.tlb_lvd_id=dis.tobd_lvd_id
			and dis.tobd_status=1 and dis.tobd_request_type='LVD_DISCOUNT'
			left join tbl_companies comp on a.tlb_company_id=comp.toc_id
			join tbl_hospitals th on a.tlb_hospital_id=th.th_id
			left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
			where cb.emr_bill_det_id is null and a.tlb_company_id > 0 
			group by a.tlb_id;
            
			/*LVD Company Bills End*/
            
			/*Rehab Company Bills Start*/
			drop temporary table if exists tmp_comp_rehab_bill;
			create temporary table if not exists tmp_comp_rehab_bill
			select a.trbd_bill_id as emr_bill_id,a.trbd_id as emr_bill_det_id,a.trbd_created_date as receipt_date,
			'FRONT_DESK' as bill_user_type,
			concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
			a.trbd_generated_by as bill_user_id
			from tbl_rehab_bill_details a
			join tbl_frontdesk fd on a.trbd_generated_by=fd.tf_id
			where a.trbd_mode='COMP' and a.trbd_created_date between lv_from_dt and lv_to_dt
			group by a.trbd_id;

			insert into emr_reports.company_bill_details
			(
			bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
			bill_amt,paid_amt,company_amt,dis_amt,
			bill_user_type,bill_user_name,bill_user_id,
			bill_date,receipt_date,run_dt
			)
			select 'REHAB_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
			a.trb_id as emr_bill_id,c.emr_bill_det_id,
			if (c.emr_bill_det_id is not null,a.trb_company,null) as comp_id,
			if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
			if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
			a.trb_total_bill_amount as bill_amt,
			sum(if(b.trbd_amount is not null,b.trbd_amount,0)) as paid_amt,
			(a.trb_total_bill_amount-if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0))-
			sum(if(b.trbd_amount is not null,b.trbd_amount,0)) as company_amt,
			if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0) as dis_amt,
			c.bill_user_type,c.bill_user_name,c.bill_user_id,
			a.trb_created_date as bill_date,c.receipt_date,current_date
			from tbl_rehab_bill a
			join tbl_rehab_bill_details b on a.trb_id=b.trbd_bill_id
			join tmp_comp_rehab_bill c on a.trb_id=c.emr_bill_id
			left join tbl_rehab_bill_discount_refund dis on a.trb_request_id=dis.tobd_rehab_id
			and dis.tobd_status=1 and dis.tobd_request_type='REHAB_DISCOUNT'
			left join tbl_companies comp on a.trb_company=comp.toc_id
			join tbl_hospitals th on a.trb_hospital_id=th.th_id
			left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
			where cb.emr_bill_det_id is null and a.trb_company > 0 
			group by a.trb_id;
			/*Rehab Company Bills End*/
            
			/*Bio Chemistry Company Bills Start*/
			drop temporary table if exists tmp_comp_biochem_bill;
			create temporary table if not exists tmp_comp_biochem_bill
			select a.ttbd_bill_id as emr_bill_id,a.ttbd_id as emr_bill_det_id,a.ttbd_created_date as receipt_date,
			'FRONT_DESK' as bill_user_type,
			concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
			a.ttbd_frontdesk as bill_user_id
			from tbl_tests_bill_details a
			left join tbl_frontdesk fd on a.ttbd_frontdesk=fd.tf_id
			where a.ttbd_case_mode='COMP' and a.ttbd_created_date between lv_from_dt and lv_to_dt
			group by a.ttbd_id;

			insert into emr_reports.company_bill_details
			(
			bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
			bill_amt,paid_amt,company_amt,dis_amt,
			bill_user_type,bill_user_name,bill_user_id,
			bill_date,receipt_date,run_dt
			)
			select 'BIO_CHEM' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
			a.ttb_id as emr_bill_id,c.emr_bill_det_id,
			if (c.emr_bill_det_id is not null,a.ttb_company_id,null) as comp_id,
			if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
			if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
			a.ttb_amount as bill_amt,
			sum(if(b.ttbd_amount is not null,b.ttbd_amount,0)) as paid_amt,
			(a.ttb_amount-if(dis.ttbd_discount_amt is not null,dis.ttbd_discount_amt,0))-
			sum(if(b.ttbd_amount is not null,b.ttbd_amount,0)) as company_amt,
			if(dis.ttbd_discount_amt is not null,dis.ttbd_discount_amt,0) as dis_amt,
			c.bill_user_type,c.bill_user_name,c.bill_user_id,
			a.ttb_created_date as bill_date,c.receipt_date,current_date
			from tbl_tests_bill a
			join tbl_tests_bill_details b on a.ttb_id=b.ttbd_bill_id
			join tmp_comp_biochem_bill c on a.ttb_id=c.emr_bill_id
			left join tbl_tests_bill_discount_refund dis on a.ttb_test_id=dis.ttbd_tests_for_bill_id
			and dis.ttbd_status=1 and dis.ttbd_request_type='BIOCHEMISTRY_DISCOUNT'
			left join tbl_companies comp on a.ttb_company_id=comp.toc_id
			join tbl_hospitals th on a.ttb_hospital_id=th.th_id
			left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
			where cb.emr_bill_det_id is null and a.ttb_company_id > 0 
			group by a.ttb_id;
			/*Bio Chemistry Company Bills end*/
        
			/*Diet Company Bills Start*/
			drop temporary table if exists tmp_comp_diet_bill;
			create temporary table if not exists tmp_comp_diet_bill
			select a.tdbd_bill_id as emr_bill_id,a.tdbd_id as emr_bill_det_id,a.tdbd_created_date as receipt_date,
			'FRONT_DESK' as bill_user_type,
			concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
			a.tdbd_frontdesk as bill_user_id
			from tbl_dietician_bill_details a
			join tbl_frontdesk fd on a.tdbd_frontdesk=fd.tf_id
			where a.tdbd_case_mode='COMP' and a.tdbd_created_date between lv_from_dt and lv_to_dt
			group by a.tdbd_id;

			insert into emr_reports.company_bill_details
			(
			bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
			bill_amt,paid_amt,company_amt,dis_amt,bill_user_type,bill_user_name,bill_user_id,bill_date,receipt_date,run_dt
			)
			select 'DIET_BILL' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
			a.tdb_id as emr_bill_id,c.emr_bill_det_id,
			if (c.emr_bill_det_id is not null,a.tdb_company_id,null) as comp_id,
			if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
			if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
			a.tdb_amount as bill_amt,
			sum(if(b.tdbd_amount is not null,b.tdbd_amount,0)) as paid_amt,
			(a.tdb_amount-if(dis.tdbd_discount_amt is not null,dis.tdbd_discount_amt,0))-
			sum(if(b.tdbd_amount is not null,b.tdbd_amount,0)) as company_amt,
			if(dis.tdbd_discount_amt is not null,dis.tdbd_discount_amt,0) as dis_amt,
			c.bill_user_type,c.bill_user_name,c.bill_user_id,
			a.tdb_created_date as bill_date,c.receipt_date,current_date
			from tbl_dietician_bill a
			join tbl_dietician_bill_details b on a.tdb_id=b.tdbd_bill_id
			join tmp_comp_diet_bill c on a.tdb_id=c.emr_bill_id
			left join tbl_dietician_bill_discount_refund dis on a.tdb_for_bill_id=dis.tdbd_for_bill_id
			and dis.tdbd_status=1 and dis.tdbd_request_type='DIETICIAN_DISCOUNT'
			left join tbl_companies comp on a.tdb_company_id=comp.toc_id
			join tbl_hospitals th on a.tdb_hospital_id=th.th_id
			left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
			where cb.emr_bill_det_id is null and a.tdb_company_id > 0 
			group by a.tdb_id;
			/*Diet Company Bills End*/
            
			/*Physician Company Bills Start*/
			drop temporary table if exists tmp_comp_phy_bill;
			create temporary table if not exists tmp_comp_phy_bill
			select a.tpbd_bill_id as emr_bill_id,a.tpbd_id as emr_bill_det_id,a.tpbd_created_date as receipt_date,
			'FRONT_DESK' as bill_user_type,
			concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
			a.tpbd_frontdesk as bill_user_id
			from tbl_physician_bill_details a
			join tbl_frontdesk fd on a.tpbd_frontdesk=fd.tf_id
			where a.tpbd_case_mode='COMP' and a.tpbd_created_date between lv_from_dt and lv_to_dt
			group by a.tpbd_id;

			insert into emr_reports.company_bill_details
			(
			bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
			bill_amt,paid_amt,company_amt,dis_amt,
			bill_user_type,bill_user_name,bill_user_id,
			bill_date,receipt_date,run_dt
			)
			select 'PHYSICIAN' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
			a.tpb_id as emr_bill_id,c.emr_bill_det_id,
			if (c.emr_bill_det_id is not null,a.tpb_company_id,null) as comp_id,
			if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
			if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
			a.tpb_amount as bill_amt,
			sum(if(b.tpbd_amount is not null,b.tpbd_amount,0)) as paid_amt,
			(a.tpb_amount-if(dis.tpbd_discount_amt is not null,dis.tpbd_discount_amt,0))-
			sum(if(b.tpbd_amount is not null,b.tpbd_amount,0)) as company_amt,
			if(dis.tpbd_discount_amt is not null,dis.tpbd_discount_amt,0) as dis_amt,
			c.bill_user_type,c.bill_user_name,c.bill_user_id,
			a.tpb_created_date as bill_date,c.receipt_date,current_date
			from tbl_physician_bill a
			join tbl_physician_bill_details b on a.tpb_id=b.tpbd_bill_id
			join tmp_comp_phy_bill c on a.tpb_id=c.emr_bill_id
			left join tbl_physician_bill_discount_refund dis on a.tpb_for_bill_id=dis.tpbd_for_bill_id
			and dis.tpbd_status=1 and dis.tpbd_request_type='PHYSICIAN_DISCOUNT'
			left join tbl_companies comp on a.tpb_company_id=comp.toc_id
			join tbl_hospitals th on a.tpb_hospital_id=th.th_id
			left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
			where cb.emr_bill_det_id is null and a.tpb_company_id > 0 
			group by a.tpb_id;
			/*Physician Company Bills End*/
            
			/*Paid Rx Company Bills Start*/
			drop temporary table if exists tmp_comp_paidrx_bill;
			create temporary table if not exists tmp_comp_paidrx_bill
			select a.tppbd_bill_id as emr_bill_id,a.tppbd_id as emr_bill_det_id,a.tppbd_created_date as receipt_date,
			'FRONT_DESK' as bill_user_type,
			concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
			a.tppbd_frontdesk_id as bill_user_id
			from tbl_paid_prescription_bill_details a
			join tbl_frontdesk fd on a.tppbd_frontdesk_id=fd.tf_id
			where a.tppbd_case_mode='COMP' and a.tppbd_created_date between lv_from_dt and lv_to_dt
			group by a.tppbd_id;

			insert into emr_reports.company_bill_details
			(
			bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
			bill_amt,paid_amt,company_amt,dis_amt,
			bill_user_type,bill_user_name,bill_user_id,
			bill_date,receipt_date,run_dt
			)
			select 'PAID_RX' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
			a.tppb_id as emr_bill_id,c.emr_bill_det_id,
			if (c.emr_bill_det_id is not null,a.tppb_company_id,null) as comp_id,
			if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
			if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
			a.tppb_amount as bill_amt,
			sum(if(b.tppbd_amount is not null,b.tppbd_amount,0)) as paid_amt,
			(a.tppb_amount-if(dis.tppbdr_auth_amt is not null,dis.tppbdr_auth_amt,0))-
			sum(if(b.tppbd_amount is not null,b.tppbd_amount,0)) as company_amt,
			if(dis.tppbdr_auth_amt is not null,dis.tppbdr_auth_amt,0) as dis_amt,
			c.bill_user_type,c.bill_user_name,c.bill_user_id,
			a.tppb_created_date as bill_date,c.receipt_date,current_date
			from tbl_paid_prescription_bill a
			join tbl_paid_prescription_bill_details b on a.tppb_id=b.tppbd_bill_id
			join tmp_comp_paidrx_bill c on a.tppb_id=c.emr_bill_id
			left join tbl_paid_prescription_bill_discount_refund dis on a.tppb_presc_id=dis.tppbdr_presc_id
			and dis.tppbdr_status=1 and dis.tppbdr_request_type='PRESC_DISCOUNT'
			left join tbl_companies comp on a.tppb_company_id=comp.toc_id
			join tbl_hospitals th on a.tppb_hospital_id=th.th_id
			left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
			where cb.emr_bill_det_id is null and a.tppb_company_id > 0 
			group by a.tppb_id;
			/*Paid Rx Company Bills End*/
            
			/*Operation Company Bills Start*/
			drop temporary table if exists tmp_comp_operation_bill;
			create temporary table if not exists tmp_comp_operation_bill
			select a.topbd_bill_id as emr_bill_id,a.topbd_id as emr_bill_det_id,a.topbd_created_date as receipt_date,
			a.topbd_cash_mode,'COUNSELOR' as bill_user_type,concat_ws(' ',tc.tc_first_name,tc.tc_last_name) as bill_user_name,
			a.topbd_counselor as bill_user_id
			from tbl_operation_bill_details a
			left join tbl_counselor tc on a.topbd_counselor=tc.tc_id
			where a.topbd_cash_mode='COMP' and a.topbd_created_date between lv_from_dt and lv_to_dt
			group by a.topbd_id;

			create index ix_emr_bill_id on tmp_comp_operation_bill(emr_bill_id);
			create index ix_emr_bill_det_id on tmp_comp_operation_bill(emr_bill_det_id);

			insert into emr_reports.company_bill_details
			(
			bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
			bill_amt,paid_amt,company_amt,dis_amt,
			bill_user_type,bill_user_name,bill_user_id,
			bill_date,receipt_date,run_dt
			)
			select 'PROCEDURE' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
			a.topb_id as emr_bill_id,c.emr_bill_det_id,
			if (c.emr_bill_det_id is not null,a.topb_company_id,null) as comp_id,
			if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
			if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
			(a.topb_amount+a.topb_room_rent+a.topb_ga_amt) as bill_amt,
			sum(if(b.topbd_amount is not null,b.topbd_amount,0)) as paid_amt,
			((a.topb_amount+a.topb_room_rent+a.topb_ga_amt)-if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0))-
			sum(if(b.topbd_amount is not null,b.topbd_amount,0)) as company_amt,
			if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0) as dis_amt,
			c.bill_user_type,c.bill_user_name,c.bill_user_id,
			a.topb_created_date as bill_date,c.receipt_date,current_date
			from tbl_operation_bill a
			join tbl_operation_bill_details b on a.topb_id=b.topbd_bill_id
			join tmp_comp_operation_bill c on a.topb_id=c.emr_bill_id
			left join tbl_operation_bill_discount_refund dis on a.topb_operation_id=dis.tobd_operation_id
			and dis.tobd_status=1 and dis.tobd_request_type='DISCOUNT'
			left join tbl_companies comp on a.topb_company_id=comp.toc_id
			join tbl_hospitals th on a.topb_hospital_id=th.th_id
			left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
			where cb.emr_bill_det_id is null and a.topb_company_id > 0 
			group by a.topb_id;			
            /*Operation Company Bills end*/
            
            /*Minor Procedure Company Bills Start*/
			drop temporary table if exists tmp_comp_minor_bill;
			create temporary table if not exists tmp_comp_minor_bill
			select a.tmobd_bill_id as emr_bill_id,a.tmobd_id as emr_bill_det_id,a.tmobd_created_date as receipt_date,
			'COUNSELOR' as bill_user_type,
			concat_ws(' ',tc.tc_first_name,tc.tc_last_name) as bill_user_name,
			a.tmobd_counselor as bill_user_id
			from tbl_minor_operation_bill_details a
			left join tbl_counselor tc on a.tmobd_counselor=tc.tc_id
			where a.tmobd_cash_mode='COMP' and a.tmobd_created_date between lv_from_dt and lv_to_dt
			group by a.tmobd_id;

			insert into emr_reports.company_bill_details
			(
			bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
			bill_amt,paid_amt,company_amt,dis_amt,
			bill_user_type,bill_user_name,bill_user_id,
			bill_date,receipt_date,run_dt
			)
			select 'MINOR_PROCEDURE' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
			a.tmob_id as emr_bill_id,c.emr_bill_det_id,
			if (c.emr_bill_det_id is not null,a.tmob_company_id,null) as comp_id,
			if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
			if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
			(a.tmob_amount+a.tmob_charges) as bill_amt,
			sum(if(b.tmobd_amount is not null,b.tmobd_amount,0)) as paid_amt,
			((a.tmob_amount+a.tmob_charges)-if(dis.tmobdr_discount_amt is not null,dis.tmobdr_discount_amt,0))-
			sum(if(b.tmobd_amount is not null,b.tmobd_amount,0)) as company_amt,
			if(dis.tmobdr_discount_amt is not null,dis.tmobdr_discount_amt,0) as dis_amt,
			c.bill_user_type,c.bill_user_name,c.bill_user_id,
			a.tmob_created_date as bill_date,c.receipt_date,current_date
			from tbl_minor_operation_bill a
			join tbl_minor_operation_bill_details b on a.tmob_id=b.tmobd_bill_id
			join tmp_comp_minor_bill c on a.tmob_id=c.emr_bill_id
			left join tbl_minor_operation_bill_discount_refund dis on a.tmob_operation_id=dis.tmobdr_case_id
			and dis.tmobdr_status=1 and dis.tmobdr_request_type='MINOR_DISCOUNT'
			left join tbl_companies comp on a.tmob_company_id=comp.toc_id
			join tbl_hospitals th on a.tmob_hospital_id=th.th_id
			left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
			where cb.emr_bill_det_id is null and a.tmob_company_id > 0 
			group by a.tmob_id;
			/*Minor Procedure Company Bills End*/
            
            /*IMC Company Bills Start*/
			drop temporary table if exists tmp_comp_imc_bill;
			create temporary table if not exists tmp_comp_imc_bill
			select a.tibd_bill_id as emr_bill_id,a.tibd_id as emr_bill_det_id,a.tibd_created_date as receipt_date,
			'COUNSELOR' as bill_user_type,
			concat_ws(' ',tc.tc_first_name,tc.tc_last_name) as bill_user_name,
			a.tibd_counselor as bill_user_id
			from tbl_imc_bill_details a
			left join tbl_counselor tc on a.tibd_counselor=tc.tc_id
			where a.tibd_case_mode='COMP' and a.tibd_created_date between lv_from_dt and lv_to_dt
			group by a.tibd_id;

			insert into emr_reports.company_bill_details
			(
			bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
			bill_amt,paid_amt,company_amt,dis_amt,bill_user_type,bill_user_name,bill_user_id,bill_date,receipt_date,run_dt
			)
			select 'IMC' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
			a.tib_id as emr_bill_id,c.emr_bill_det_id,
			if (c.emr_bill_det_id is not null,a.tib_company_id,null) as comp_id,
			if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
			if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
			(a.tib_amount+a.tib_per_day_price) as bill_amt,
			sum(if(b.tibd_amount is not null,b.tibd_amount,0)) as paid_amt,
			((a.tib_amount+a.tib_per_day_price)-if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0))-
			sum(if(b.tibd_amount is not null,b.tibd_amount,0)) as company_amt,
			if(dis.tobd_discount_amt is not null,dis.tobd_discount_amt,0) as dis_amt,
			c.bill_user_type,c.bill_user_name,c.bill_user_id,
			a.tib_created_date as bill_date,c.receipt_date,current_date
			from tbl_imc_bill a
			join tbl_imc_bill_details b on a.tib_id=b.tibd_bill_id
			join tmp_comp_imc_bill c on a.tib_id=c.emr_bill_id
			left join tbl_imc_bill_discount_refund dis on a.tib_imc_id=dis.tobd_imc_id
			and dis.tobd_status=1 and dis.tobd_request_type='IMC_DISCOUNT'
			left join tbl_companies comp on a.tib_company_id=comp.toc_id
			join tbl_hospitals th on a.tib_hospital_id=th.th_id
			left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
			where cb.emr_bill_det_id is null and a.tib_company_id > 0 
			group by a.tib_id;
			/*IMC Company Bills End*/
            
			/*OPD Generic Company Bills Start*/
			drop temporary table if exists tmp_comp_opdgeneric_bill;
			create temporary table if not exists tmp_comp_opdgeneric_bill
			select a.transaction_id as emr_bill_id,a.id as emr_bill_det_id,a.created_date as receipt_date,
			'FRONT_DESK' as bill_user_type,
			concat_ws(' ',fd.tf_first_name,fd.tf_last_name) as bill_user_name,
			a.frontdesk_id as bill_user_id
			from opd_service_bill_details a
			join tbl_frontdesk fd on a.frontdesk_id=fd.tf_id
			where a.case_mode='COMP' and a.created_date between lv_from_dt and lv_to_dt
			group by a.id;

			insert into emr_reports.company_bill_details
			(
			bill_type,hosp_code,hosp_id,emr_bill_id,emr_bill_det_id,comp_id,company_name,company_code,
			bill_amt,paid_amt,company_amt,dis_amt,
			bill_user_type,bill_user_name,bill_user_id,
			bill_date,receipt_date,run_dt
			)
			select 'OPD_GENERIC' as bill_type,th.th_sap_code as hosp_code,th.th_id as hosp_id,
			a.transaction_id as emr_bill_id,c.emr_bill_det_id,
			if (c.emr_bill_det_id is not null,a.company_id,null) as comp_id,
			if (c.emr_bill_det_id is not null,comp.toc_company_name,null) as company_name,
			if (c.emr_bill_det_id is not null,comp.toc_sap_key,null) as company_code,
			a.total_amount as bill_amt,
			sum(if(b.amount is not null,b.amount,0)) as paid_amt,
			(a.total_amount-if(dis.osbdr_discount_amt is not null,dis.osbdr_discount_amt,0))-
			sum(if(b.amount is not null,b.amount,0)) as company_amt,
			if(dis.osbdr_discount_amt is not null,dis.osbdr_discount_amt,0) as dis_amt,
			c.bill_user_type,c.bill_user_name,c.bill_user_id,
			a.bill_create_date as bill_date,c.receipt_date,current_date
			from opd_service_bill a
			join opd_service_bill_details b on a.transaction_id=b.transaction_id
			join tmp_comp_opdgeneric_bill c on a.transaction_id=c.emr_bill_id
			left join opd_service_bill_discount_refund dis on a.request_id=dis.osbdr_request_id
			and dis.osbdr_status='1' and dis.osbdr_request_type='PHY_DISCOUNT'
			left join tbl_companies comp on a.company_id=comp.toc_id
			join tbl_hospitals th on a.hos_code=th.th_sap_code
			left join emr_reports.company_bill_details cb on c.emr_bill_det_id=cb.emr_bill_det_id
			where cb.emr_bill_det_id is null and a.company_id > 0 
			group by a.transaction_id;
			/*OPD Generic Company Bills End*/       


	insert into emr_reports.tbl_jobs_tables (tablename,job_name,table_description,last_run_dt,last_run_time)
	values ('company_bill_details','insupd_company_bill_details','all comapny bills data and Amount inserted in the table',current_date,current_time);
end$$
DELIMITER ;
