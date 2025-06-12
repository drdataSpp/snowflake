-- Set the active role
USE ROLE SYSADMIN;

-- Create a transient database if it doesn't exist
CREATE TRANSIENT DATABASE IF NOT EXISTS super_store;

-- Create schemas
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;

-- Set context to the bronze schema
USE SCHEMA bronze;

-- Create an external stage with Snowflake full encryption
CREATE STAGE landing_zone
    ENCRYPTION = (TYPE = 'SNOWFLAKE_FULL');

-- List files in the landing_zone stage
LS @landing_zone;
-- landing_zone/Sample - Superstore.csv

-- Create a file format to read the CSV file
CREATE OR REPLACE FILE FORMAT my_csv_format
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    PARSE_HEADER = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    NULL_IF = ('', 'NULL')
    EMPTY_FIELD_AS_NULL = TRUE
    DATE_FORMAT = 'MM/DD/YYYY'
    TIME_FORMAT = 'AUTO'
    ENCODING = 'ISO-8859-1';

-- Create a table using inferred schema from the file
CREATE OR REPLACE TABLE super_store_sales
    USING TEMPLATE (
        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        FROM TABLE(
            INFER_SCHEMA(
                LOCATION => '@landing_zone',
                FILE_FORMAT => 'my_csv_format'
            )
        )
    );

-- Describe the created table
DESC TABLE super_store_sales;

-- Load data into the table from the stage
COPY INTO super_store_sales 
    FROM @landing_zone
    FILE_FORMAT = (FORMAT_NAME = 'my_csv_format')
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- File information and stats (commented for reference)
/*
~/Downloads/Sample - Superstore.csv
$ wc -l *.csv
9995 Sample - Superstore.csv

landing_zone/Sample - Superstore.csv    LOADED    9994    9994    1    0
*/

-- Preview data
SELECT * 
FROM super_store_sales
LIMIT 100;
