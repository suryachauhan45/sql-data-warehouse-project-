CREATE OR ALTER PROCEDURE silver.load_silver as
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME,@batch_start DATETIME ,@batch_end DATETIME;
	SET @batch_start = GETDATE();
	BEGIN TRY
		PRINT '===============================================';
		PRINT ' LOADING SILVER  LAYER';
		PRINT '===============================================';
		-----------------------------------------------
		--INSERTING INTO SILVER 
		-----------------------------------------------
		-----for crm_cust_info
		PRINT '----------------------------------------';
		PRINT 'LOADING CRM TABLES';
		PRINT '----------------------------------------';
		
		SET @start_time = GETDATE();
	
		PRINT'TRUNCATING TABLE :silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT'INSERTING DATA INTO : crm_cust_info';

		INSERT INTO silver.crm_cust_info(cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date)
		select cst_id,cst_key,
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE
			WHEN UPPER(TRIM(cst_marital_status))='M'
			THEN 'Married'
			WHEN UPPER(TRIM(cst_marital_status))='S'
			THEN 'Single'
			ELSE'n/a'
			END AS cst_marital_status,
			CASE 
			WHEN UPPER(TRIM(cst_gndr)) = 'M'
			THEN 'Male'
			WHEN UPPER(TRIM(cst_gndr))='F'
			THEN 'Female'
			ELSE 'n/a' 
			END AS
			cst_gndr,
			cst_create_date from
		(select * from 
		(select * , row_number() over(partition by cst_id order by cst_create_date desc) as flag_last
		from bronze.crm_cust_info
		where cst_id is not null) as a
		where flag_last=1) as b;

		SET @end_time = GETDATE();

		PRINT'load duration : ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +' seconds'
		----for crm_prd_info
		--updating ddl for  crm_prd_info
		SET @start_time = GETDATE();

		IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
			DROP TABLE silver.crm_prd_info;

		CREATE TABLE silver.crm_prd_info (
			prd_id       INT,
			prd_key      NVARCHAR(50),
			cat_id       NVARCHAR(50),
			prd_nm       NVARCHAR(50),
			prd_cost     INT,
			prd_line     NVARCHAR(50),
			prd_start_dt DATE,
			prd_end_dt   DATE,
			dwh_create_date     DATETIME DEFAULT GETDATE()
		);

		-----------------------------------
		--INSERTING INTO silver.crm_prd_info
		------------------------------------
	
		PRINT'TRUNCATING TABLE :silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT'INSERTING DATA INTO : silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(prd_id,cat_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)


		select prd_id,
			replace(substring(prd_key,1,5),'-','_') as cat_id,--extracts catiegory id 
			substring(prd_key,7,len(prd_key)) as prd_key ,--extracts prdoduct key
			prd_nm,
			coalesce( prd_cost,0) as prd_cost,
			case 
			when UPPER(prd_line) ='M' THEN 'Mountain'
			when UPPER(prd_line) ='S' THEN 'Other sales'
			when UPPER(prd_line) ='T' THEN 'Touring'
			when UPPER(prd_line) ='R' THEN 'Road'
			else 'n/a' 
			end prd_line,--gives descriptive names for product line
			cast(prd_start_dt as date) as prd_start_date ,
			cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)-1 AS date) as 
			-- calculates end date as 1 day before the next start date
			prd_end_dt from bronze.crm_prd_info;

			SET @end_time = GETDATE();
			PRINT'load duration : ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +' seconds';
			-------------------------------------------
			-- for sales_details
		--updating ddl for  silver.crm_sales_details
		SET @start_time = GETDATE();

		IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
			DROP TABLE silver.crm_sales_details;
	

		CREATE TABLE silver.crm_sales_details (
			sls_ord_num  NVARCHAR(50),
			sls_prd_key  NVARCHAR(50),
			sls_cust_id  INT,
			sls_order_dt DATE,
			sls_ship_dt  DATE,
			sls_due_dt   DATE,
			sls_sales    INT,
			sls_quantity INT,
			sls_price    INT,
			dwh_create_date     DATETIME DEFAULT GETDATE()
		);
		----------------------------------------------
		--INSERTING INTO silver.crm_sales_details
	
		PRINT'TRUNCATING TABLE :silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT 'INSERTING DATA INTO : silver.crm_sales_details';

		INSERT INTO silver.crm_sales_details(sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,
		sls_sales,sls_quantity,sls_price)
			select sls_ord_num,
				sls_prd_key,
				sls_cust_id,
				case 
				when sls_order_dt = 0 or len(sls_order_dt) != 8 THEN Null 
				else cast(cast(sls_order_dt as varchar) as DATE) 
				end --
				sls_order_dt,
				case 
				when sls_ship_dt = 0 or len(sls_ship_dt) != 8 THEN Null 
				else cast(cast(sls_ship_dt as varchar) as DATE) 
				end
				sls_ship_dt,
				case 
				when sls_due_dt = 0 or len(sls_due_dt) != 8 THEN Null 
				else cast(cast(sls_due_dt as varchar) as DATE) 
				end
				sls_due_dt,
				case 
				when sls_sales <=0 or sls_sales is null or sls_sales != abs(sls_quantity)*abs(sls_price) 
				then abs(sls_quantity)*abs(sls_price) 
				else sls_sales 
				end sls_sales,--recalculate sales if original value is missing or invalid 
				sls_quantity,
				case 
				when sls_price is null or sls_price <= 0 
				then sls_sales/nullif(sls_quantity,0)
				else sls_price 
				end sls_price-- derive price if the original value is invalid
				from bronze.crm_sales_details ;

				
			SET @end_time = GETDATE();
			PRINT'load duration : ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +' seconds';
			-------------------------------------------------
			----INSERTING INTO silver.erp_cust_az12----------
			-------------------------------------------------
			SET @start_time = GETDATE();

		PRINT '----------------------------------------';
		PRINT 'LOADING ERP TABLES';
		PRINT '----------------------------------------';

		PRINT'TRUNCATING TABLE :silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;

		PRINT 'INSERTING DATA INTO : silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12(cid,bdate,gen)
			select
		case 
		when cid like 'NAS%' THEN SUBSTRING(cid,4,len(cid))
		ELSE cid
		END as cid,
		case 
		when bdate > getdate() then null 
		else bdate
		end as bdate,
		case 
		when gen in ('M','MALE') THEN 'Male'
		when gen in ('F','FEMALE') THEN 'Female'
		else 'n/a' 
		end as gen
		from bronze.erp_cust_az12;

		SET @end_time = GETDATE();
		PRINT'load duration : ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +' seconds';
		--------------------------------------------
		-------INSERTING INTO silver.erp_loc_a101---
		--------------------------------------------
	    SET @start_time = GETDATE();
	
		PRINT'TRUNCATING TABLE :silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT 'INSERTING DATA INTO : silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101(cid,cntry)
		select replace(cid,'-','') as cid,
		CASE 
		WHEN upper(trim(cntry)) ='USA' or upper(trim(cntry)) ='UNITED STATES' or upper(trim(cntry)) = 'US' 
		THEN 'United States'
		WHEN upper(trim(cntry))= 'DE' THEN 'Germany'
		WHEN cntry is null or cntry='' THEN 'n/a'
		ELSE TRIM(cntry) 
		END AS cid
		from bronze.erp_loc_a101;

		SET @end_time = GETDATE();
		PRINT'load duration : ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +' seconds';

		------------------------------------------
		----INSERTING INTO silver.erp_px_cat_g1v2
		------------------------------------------
	SET @start_time = GETDATE();

		PRINT'TRUNCATING TABLE :silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT 'INSERTING DATA INTO : silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
		SELECT id,cat,subcat,maintenance FROM bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT'load duration : ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +' seconds';
---------------------------------------------------------------------------
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
	SET @batch_end = GETDATE();
	PRINT'------------------------------------'
	PRINT 'Total duration for loading silver layer ' + CAST(DATEDIFF(second,@batch_start,@batch_end) AS NVARCHAR) +' seconds'


END;

