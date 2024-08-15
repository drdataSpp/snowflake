USE ROLE SYSADMIN;
EXECUTE IMMEDIATE FROM @snowflake_repo/branches/snowflake_git_integration/snowflake_git_integration/tables/test_db.dbt.customer_table.sql;
EXECUTE IMMEDIATE FROM @snowflake_repo/branches/snowflake_git_integration/snowflake_git_integration/tables/test_dbt.dbt.call_center.sql;