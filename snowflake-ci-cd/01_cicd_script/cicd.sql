/* 1. Setting up Git API and Repository objects */

USE SCHEMA TEST_DB.ADMIN; 

USE ROLE ACCOUNTADMIN;

/* Privs for SYSADMIN to create the below-objects */
GRANT CREATE GIT REPOSITORY ON SCHEMA TEST_DB.ADMIN TO ROLE SYSADMIN; --schema level object
GRANT CREATE API INTEGRATION ON ACCOUNT TO ROLE SYSADMIN; --account level object

USE ROLE SYSADMIN;

CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/drdataSpp/snowflake.git')
  ENABLED = TRUE;


CREATE OR REPLACE GIT REPOSITORY drdataspp_repo
    ORIGIN = 'https://github.com/drdataSpp/snowflake.git'
    API_INTEGRATION = git_api_integration;

--###########################################################################################
    
/* 2. SnowSQL on the GitHub repo */

DESC GIT REPOSITORY drdataspp_repo;

SHOW GIT BRANCHES IN GIT REPOSITORY drdataspp_repo;

/* 
    master	/branches/master --master branch
    snowflake-ci-cd-trial-1	/branches/snowflake-ci-cd-trial-1 --feature branch
*/

--to fetch changes in the repo including new branches
ALTER GIT REPOSITORY drdataspp_repo FETCH;

--listing new sql files in feature branch
LiST @drdataspp_repo/branches/snowflake-ci-cd-trial-1 PATTERN = '.*sql*';

--###########################################################################################

/* 3. Capturing the changes between master and feature branch and deploying them */


--MASTER BRANCH
BEGIN;

SHOW TRANSACTIONS;

LIST @drdataspp_repo/branches/master PATTERN = '.*sql*';

CREATE OR REPLACE TEMPORARY TABLE RS_SCAN_MASTER AS
SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

COMMIT;

-- FEATURE BRANCH
BEGIN;

SHOW TRANSACTIONS;

LIST @drdataspp_repo/branches/snowflake-ci-cd-trial-1 PATTERN = '.*sql*';

CREATE OR REPLACE TEMPORARY TABLE RS_SCAN_feature AS
SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

COMMIT;

--Finding diff using SHA1 hash column
SELECT CONCAT('''', UPPER('@"test_db".'), UPPER('"admin".'), "name", '''') 
FROM TEST_DB.ADMIN.RS_SCAN_FEATURE f
WHERE f."sha1" NOT IN (SELECT "sha1" from TEST_DB.ADMIN.RS_SCAN_MASTER);

--Deploy
EXECUTE IMMEDIATE FROM '@"TEST_DB"."ADMIN".drdataspp_repo/branches/snowflake-ci-cd-trial-1/snowflake-ci-cd/databases/01_staging_db_creation.sql';
EXECUTE IMMEDIATE FROM '@"TEST_DB"."ADMIN".drdataspp_repo/branches/snowflake-ci-cd-trial-1/snowflake-ci-cd/schemas/01_staging_schema_creation.sql';

/* ####################################################### */

/* Table DDL change - declarative method */

CREATE OR ALTER TABLE test_tbl(
id NUMBER
,NAME STRING
);

insert into test_tbl
VALUES(1), (2);

TABLE test_tbl;

--The above sql will add new column and not affect existing data.

/* ####################################################### */
