# Snowflake Git Repository & Deploying SnowSQLs from Source Control 💫 ✨

## Prerequisites

Before starting, ensure you have the following:

- Snowflake account with the required privileges.
- A GitHub repository with SQL scripts ready for deployment.

## Setting Up the Git Repository in Snowflake

### 1. Switch to SYSADMIN Role

Start by switching to the `SYSADMIN` role to ensure you have the necessary permissions:

```sql
USE ROLE SYSADMIN;
```

### 2. Create Schema

Create a schema to store the Git repository and related objects:

```sql
USE DATABASE TEST_DB;

CREATE OR REPLACE SCHEMA TEST_DB.GIT
COMMENT = $$Used to store git repo and dependent objects$$;
```

### 3. Create Internal Stage

**OPTIONAL** - Create an internal named stage to store SQL files that will be deployed:

```sql
CREATE OR REPLACE STAGE GIT_STAGE
COMMENT = $$Internal stage to store .sql files that will be deployed using Snowflake's EXECUTE IMMEDIATE FROM command.$$;
```
This is an alternative to deploy SQLs over Git Repo.

### 4. Create API Integration

Create an external API integration to connect Snowflake with GitHub:

```sql
CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/<org_name>')
  ENABLED = TRUE;
```

### 5. Create the Git Repository Object

Create a Snowflake Git repository object that points to your GitHub repository:

```sql
USE SCHEMA TEST_DB.GIT;

CREATE OR REPLACE GIT REPOSITORY snowflake_repo
  ORIGIN = 'https://github.com/<org_name>/<repo>.git'
  API_INTEGRATION = git_api_integration
  COMMENT = 'Git repository for Snowflake SQLs';
```

### 6. Querying the Git Repository

Viewing available files:

```sql
SHOW GIT BRANCHES IN TEST_DB.GIT.SNOWFLAKE_REPO;

--Lists all files undert that sub-directory from master branch
LS @TEST_DB.GIT.SNOWFLAKE_REPO/branches/master/<sub_dir>;
```

### 7. Fetch Data from the Git Repository

Fetch the data from your repository:

```sql
ALTER GIT REPOSITORY TEST_DB.GIT.snowflake_repo FETCH;
```

---

## Preparing SQL Scripts for Deployment

### 1. Create SQL Scripts

Here are two example SQL scripts that create transient tables:

```sql
USE ROLE SYSADMIN;

CREATE OR REPLACE TRANSIENT TABLE TEST_DB.DBT.CUSTOMER_TABLE AS
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER
LIMIT 10;
```

*File Name: `tables/test_db.dbt.customer_table.sql`*

```sql
USE ROLE SYSADMIN;

CREATE OR REPLACE TRANSIENT TABLE TEST_DB.DBT.CALL_CENTER AS
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CALL_CENTER
LIMIT 10;
```

*File Name: `tables/test_dbt.dbt.call_center.sql`*

### 2. Create a Master Deployment Script

This script will execute the SQL files stored in the Git repository:

```sql
USE ROLE SYSADMIN;

--Order the files in the logical order of deployment
EXECUTE IMMEDIATE FROM @snowflake_repo/branches/snowflake_git_integration/snowflake_git_integration/tables/test_db.dbt.customer_table.sql;
EXECUTE IMMEDIATE FROM @snowflake_repo/branches/snowflake_git_integration/snowflake_git_integration/tables/test_dbt.dbt.call_center.sql;
```

*File Name: `git_master_scripts/deploy_master_test_1.sql`*

#### In the above SQL:
- ***EXECUTE IMMEDIATE FROM*** - is the SnowSQL to run all SQLs present in a .sql file
- ***@snowflake_repo*** - is the Git Repo object that we created earlier.
- ***@snowflake_repo/branches*** - Under this path, we will have all branches under the repo we created earlier. Master/ Main branch + feature branches.
- ***@snowflake_repo/branches/snowflake_git_integration*** - Anything other than master or main after **branches/** denotes that a SQL will be deployed from a feature branch and not master/ main branch.
  - For NON-PROD deployments, use ***@snowflake_repo/branches/<feature_branch_name>***
  - For PROD deployments, always use ***@snowflake_repo/branches/master* or *@snowflake_repo/branches/main***     
- ***@snowflake_repo/branches/snowflake_git_integration/snowflake_git_integration/tables*** - Here, snowflake_git_integration/ & tables/ are directory structure present in your feature or master branch.
- ***@snowflake_repo/branches/snowflake_git_integration/snowflake_git_integration/tables/test_dbt.dbt.call_center.sql*** - The .sql file that holds the SQL we want to be ran in Snowflake Data Platform.

---

## Deploying SQL Scripts from GitHub

### 1. Fetch Latest Changes from the Git Repository

Before deploying, ensure you have the latest changes from your GitHub repository:

```sql
ALTER GIT REPOSITORY SNOWFLAKE_REPO;
```

### 2. Execute the Master Deployment Script

Finally, run the master deployment script:

```sql
USE SCHEMA TEST_DB.GIT; /* Schema where git object was created */

EXECUTE IMMEDIATE FROM @snowflake_repo/branches/snowflake_git_integration/snowflake_git_integration/git_master_scripts/deploy_master_test_1.sql;
```

---

## Conclusion

By following these steps, you have successfully created a Git repository within Snowflake and deployed SQL scripts directly from source control. This approach enables streamlined deployments and version control for your Snowflake projects.
