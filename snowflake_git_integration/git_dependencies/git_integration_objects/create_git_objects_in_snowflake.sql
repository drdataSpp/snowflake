USE ROLE SYSADMIN;

--TEST_DB exists.
USE DATABASE TEST_DB;

--schema creation.
CREATE OR REPLACE SCHEMA TEST_DB.GIT
COMMENT = $$Used to store git repo and dependent objects$$;

--internal named stage creation.
CREATE OR REPLACE STAGE GIT_STAGE
COMMENT = $$Internal stage to store .sql files that will be deployed using Snowflake's EXECUTE IMMEDIATE FROM command.$$;

--external API integration creation.
CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/<org_name>')
  ENABLED = TRUE;

--creating the git repo object.
CREATE OR REPLACE GIT REPOSITORY snowflake_repo
  ORIGIN = 'https://github.com/<org_name>/<dir>.git'
  API_INTEGRATION = git_api_integration
  -- GIT_CREDENTIALS = <secret_name>
  COMMENT = 'Git repository for Snowflake SQLs'
;

--Fetch data from your repo.
ALTER GIT REPOSITORY TEST_DB.GIT.snowflake_repo FETCH;