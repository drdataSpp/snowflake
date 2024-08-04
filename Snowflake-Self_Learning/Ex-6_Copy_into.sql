USE ROLE ACCOUNTADMIN;
USE WAREHOUSE ETL_WH;
USE DEV;

--CREATING TGT TABLE

CREATE OR REPLACE TABLE RAW.CREDIT_CARDS

(
  CUSTOMER_NAME STRING,
  CREDIT_CARD STRING,
  TYPE STRING,
  CCV INTEGER,
  EXP_DATE STRING
);

-- CREATING FILE FORMAT
CREATE FILE FORMAT GEN_CSV
TYPE = CSV
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- CREATING EXTERNAL STAGE
CREATE OR REPLACE STAGE AWS_EXT_STAGE
url='s3://snowflake-cookbook/Chapter03/r2'
FILE_FORMAT = GEN_CSV;

--COPY INTO
COPY INTO RAW.CREDIT_CARDS
FROM @C3_R2_STAGE/cc_info.csv;

--In the above statement, we have specified the path until 's3://snowflake-cookbook/Chapter03/r2', when loading data, I am adding the file name so that Snowflake will understand and load only one file.

--Loading data from internal named stage to table
COPY INTO CUSTOMER
FROM @CUSTOMER_STAGE;

--Once data loading is successful, then let's remove the contents in the internal stage to save cost.
REMOVE @CUSTOMER_STAGE;