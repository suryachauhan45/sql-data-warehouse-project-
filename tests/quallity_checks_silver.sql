------------------------------------------------
--checks and tests for crm_cust_info
------------------------------------------------
--check for nulls and duplicates in primary key 
--expectation: no results 
use datawarehouse;
select cst_id ,count(cst_id) from bronze.crm_cust_info
group by cst_id having count(cst_id)>1;
select cst_id ,count(cst_id) from silver.crm_cust_info
group by cst_id having count(cst_id)>1;
--check for unwanted spaces 
select cst_firstname from bronze.crm_cust_info
where cst_firstname != TRIM(cst_firstname);
--check for columns with data inconsistency and for standardisation
select distinct cst_marital_status  from bronze.crm_cust_info;
select distinct cst_gndr from bronze.crm_cust_info

select * from silver.crm_cust_info;

------------------------------------------------
--checks and tests for crm_prd_info
------------------------------------------------
--check for nulls and duplicates in primary key 
--expectation: no results
select prd_id from silver.crm_prd_info
group by prd_id 
having count(prd_id) >1;
--check for negative numbers 
--expectations : no result
select prd_cost from silver.crm_prd_info
where prd_cost <0;
--check for invalid dates 
select prd_start_dt ,prd_end_dt from silver.crm_prd_info
where prd_start_dt>prd_end_dt;

--final silver.crm_prd_info
select * from silver.crm_prd_info;
-------------------------------------------------------------
--checks and tests for sales_details
-------------------------------------------------------------
select * from bronze.crm_sales_details ;
--checking for unwanted spaces 
--expectations : no results
select sls_ord_num from bronze.crm_sales_details
where sls_ord_num!=trim(sls_ord_num);
select sls_prd_key from bronze.crm_sales_details
where sls_prd_key!=trim(sls_prd_key);
--check for negative value in dates
select nullif(sls_order_dt,0) from bronze.crm_sales_details
where sls_order_dt <=0
or len(sls_order_dt) != 8 
or sls_order_dt > 20500101 
or sls_order_dt < 19000101
select sls_ship_dt from bronze.crm_sales_details
where sls_ship_dt <=0 ;
select sls_due_dt from bronze.crm_sales_details
where sls_due_dt <=0 ;
--check for data inconsistencyin sales,price, quantity

select sls_sales,sls_quantity,
sls_price from bronze.crm_sales_details
where sls_sales != sls_quantity*sls_price
or sls_sales is null or sls_quantity is null or sls_price is  null 
or sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0;

---check final silver.crm_sales_details
select * from  silver.crm_sales_details;
-------------------------------------------------------
	--------FOR bronze.erp_cust_az12 ----------------------
	-------------------------------------------------------
	--check for inconsistencies in birthdate 
	select bdate from bronze.erp_cust_az12 
	where bdate >getdate();
	--data inconsistencies in gender column
	select distinct gen from bronze.erp_cust_az12;
---final check for silver.erp_cust_az12
select * from silver.erp_cust_az12;

------------------------------------------
----checks and tests for bronze.erp_loc_a101
select * from bronze.erp_loc_a101;
--check for data inconsistencies 
select cid from bronze.erp_loc_a101;
--check data standardisation and inconsistencies in country column
select  distinct cntry from bronze.erp_loc_a101

----Checks and tests for bronze.erp_px_cat_g1v2
-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    * 
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT 
    maintenance 
FROM silver.erp_px_cat_g1v2;


