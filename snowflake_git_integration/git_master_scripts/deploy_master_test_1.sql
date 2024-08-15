USE ROLE SYSADMIN;

EXECUTE IMMEDIATE FROM @TEST_DB.GIT.SNOWFLAKE_REPO/snowflake_git_integration/snowflake_git_integration/tables/test_db.dbt.customer_table.sql;
EXECUTE IMMEDIATE FROM @TEST_DB.GIT.SNOWFLAKE_REPO/branches/snowflake_git_integration/snowflake_git_integration/tables/test_dbt.dbt.call_center.sql;