--CREATING THE DATABASE AND SCHEMA
--AND SCHEMAS INSIDE THE DATABASE AS bronze,silver,gold

USE master;
GO 

IF EXISTS (SELECT 1 FROM sys.databases WHERE name= 'datawarehouse')
BEGIN 
	 ALTER DATABASE datawarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE ;
	 DROP DATABASE datawarehouse;
END;
	 GO
--create datebase named 'datawarehouse'
CREATE DATABASE datawarehouse;
GO

USE datawarehouse;
GO 

--create schemas
CREATE SCHEMA bronze;
GO 

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
