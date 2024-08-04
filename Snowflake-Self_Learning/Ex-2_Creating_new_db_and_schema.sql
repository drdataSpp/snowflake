/*
-- Order of execution: One.
CREATE DATABASE COOKBOOK;

-- Order of execution: Two.
USE DATABASE COOKBOOK;

CREATE OR REPLACE TABLE MY_FIRST_TABLE
(
    ID STRING,
    NAME STRING
);

-- Order of execution: Three.
SELECT * FROM MY_FIRST_TABLE;

-- returns none 
*/

--Creating a database with a default data retention period
CREATE DATABASE my_first_database
COMMENT = 'My first database';

--Creating a database with 15 days of data retention period
CREATE DATABASE production_database
DATA_RETENTION_TIME_IN_DAYS = 15
COMMENT = 'Critical production database';

--Creating a database without the fail-safe storage option
CREATE TRANSIENT DATABASE temporary_database
DATA_RETENTION_TIME_IN_DAYS = 0
COMMENT = 'Temporary database for ETL processing';

--Creating two new schemas

--Schema One under production_database, this will have all configs as prod db
USE DATABASE production_database
CREATE SCHEMA pre_prod
COMMENT = 'This is Pre-Production Schema';

--Schema Two under temporary_database, this will have all configs as temp db
USE DATABASE temporary_database
CREATE SCHEMA test_env
COMMENT = 'This is test env schema';



--Creating a database for ETL purposes
CREATE TRANSIENT DATABASE DEV
DATA_RETENTION_TIME_IN_DAYS = 0
COMMENT = 'Development DB';

CREATE SCHEMA RAW
COMMENT = 'RAW schema holds all source data as it is with 0 txfms';

CREATE SCHEMA TXFM
COMMENT = 'TXFM schema holds transformed data from RAW schema';