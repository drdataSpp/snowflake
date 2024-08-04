# Snowflake Self-Learning Documentation

A free account was created using the "Enterprise" edition.
Enterprise edition supports multi-cluster virtual warehouses and up to 90 days of time travel.

Snowflake is a Software as a Service (Saas), it is hosted on one of the major cloud providers (I'm using Azure for this course).

To access a Snowflake instance, we don't have to log in to the cloud provider console but can use a URL link to access the Snowflake instance. Snowflake offers users a single and consistent entry point (that ends with snowflakecomputing.com).

## Topic 1: Creating a Multi-cluster Warehouse

- To create an MC WH, we must switch to **SYSADMIN** or a higher role
- Understanding the configuration of the Multi-cluster Warehouse:
	- The MIN and MAX cluster counts should be set differently, by doing this, the MC WH will start with the value set to the MIN_CLUSTER_COUNT as the number of concurrent queries increases and if they exceed the server's capacity and starts to be in a queue, the MC WH will scale up to the MAX_CLUSTER_COUNT.
	- Choosing 'Economy' as the scaling policy will scale the WH only when there are enough queries to keep the additional cluster busy for 6 minutes.
	- AUTO_SUSPEND will automatically suspend the WH if there's no activity for the minutes mentioned.
	- Nodes and WH size:
			XS 	= 1 Node
			,S 	= 2 Nodes
			,M	= 4 Nodes
			,L	= 8 Nodes
			,XL	= 16 Nodes
	
		- Having the highest number of nodes will not always come up with the highest performance, WH's nodes and size should be decided based on the activity that's going to take place on the WH, for example, DBA and admins can benefit out of S, Reporting queries can use M, Data Scientists can use XL and Interactive queries can happen on a L MC WH.
	- AUTO_RESUME will automatically resume a suspended WH once it receives a query.
	- INITIALLY_SUSPENDED, setting true will create the WH in a suspended state.
	
## Topic 2: Understanding the Snowflake UI

- **Worksheets:** Worksheets is the default view that shows up when we open a Snowflake instance and that's where we can write and execute our queries.
- **Databases:** Under Data > Databases, we can find the list of available databases, the owner of the DB, the time when it was created, and we can create new DBs if we have the right privileges.
- **Warehouses:** Under Admin > Warehouses, we can find the list of available Warehouses, the configuration of the Warehouse, the owner of the Warehouse, and the time when it was created, and we can create new Warehouses if we have the right privileges.

## Topic 3: Creating a new DB and Schema in the Multi-cluster Warehouse

- Worksheets can be renamed and organized under a folder, I have created a new folder called 'Self learning' and saved my SQL worksheets based on the query and purpose for better documentation purposes.

- To create a new DB, open or create new SQL worksheets, select the appropriate user with relevant privileges under the 'Run as' option and the warehouse in which the DB should be created. These can be found in the top-right corner of the Web UI. Write and execute the create DB SQL.

- Once the DB is created, write the SQL to create a table and execute it.

- Worksheets can have it's combination of role, virtual warehouse, database, and schema. To execute a query successfully, the user should have a valid role and virtual warehouse. To query a table from a different database and not the one under the database selected in the worksheet, one can fully qualify the database, schema, and table name to do so.

- To check a newly created Database in Snowflake, Use `SHOW DATABASES LIKE '{database_name}' `

- retention_time:
	- When creating a new database using the standard `CREATE DATABASE ` SQL statement, the retention_time of that Database is defaulted to 1 or 1 day. This means Snowflake preserves the state of data for a day.
	
	- To preserve data for more than one day, we need the Enterprise edition and need to set the retention_time while creating an object using the parameter **DATA_RETENTION_TIME_IN_DAYS**
	
	- The time travel option is highly recommended for production databases but not for development and temporary databases. Removing time travel and fail-safe storage options in development regions will help in the reduction of storage costs.
	
	- To remove the fail-safe storage option while creating a database, use `CREATE TRANSIENT DATABASE` SQL over `CREATE DATABASE` SQL.
	
	- Time travel option can be configured later after creating a database using the `ALTER DATABASE {name} SET DATA_RETENTION_TIME_IN_DAYS = ` SQL.
	
	- ETL processing databases and tables (in the Development region) should be created as transient ones and DATA_RETENTION_TIME_IN_DAYS should be set to zero. These tables will often get new data, updates in existing data, and deletes, if these tables are created with fail-safe storage and time travel option, we will end up incurring costs for every change that will happen to that table.
	
	- Creating a new database with DATA_RETENTION_TIME_IN_DAYS set to zero and no fail-safe storage option will create the objects within that database with the same configs, but this config can be manually over-written while creating tables under that database.
	
- Schema:
	- Creating schema under a database will create the schema the same as the Database config unless specified.
	
	- To create a new schema `USE DATABASE {db_name} CREATE SCHEMA {schema_name}`, to view a created schema, `SHOW SCHEMAS LIKE '%{schema_name}%' IN DATABASE {db_name};`
	
	- Similar to Databases, schemas can also be created using `CREATE TRANSIENT SCHEMA` to save on storage costs.
	
	- Whenever a new database is created a 'public' schema is created by default along with 'information schema'. The information schema will hold the metadata information like tables, columns, and data types.
	
## Topic 4: Creating a new Table in the Multi-cluster Warehouse

- Open a worksheet, select the database and schema where you wish to create the table, and use the CREATE TABLE SQL to create the new table.

- To verify the table creation and metadata information, use `DESCRIBE TABLE {table_name};` SQL. This shows all the column and column information in that table.

- If a table's column is created with a wrong datatype or name, we can either use ALTER TABLE SQL to update the column, or use the new DDL but with `CREATE OT REPLACE TABLE` SQL.

- `REPLACE` is a shorthand for this traditional SQL `DROP TABLE IF EXISTS; CREATE TABLE;`.

- Difference between Deep copy and Shallow copy in Tables:
	- Deep copy is performed using *CTAS* or `CREATE OR REPLACE TABLE customers_deep_copy AS SELECT * FROM customers;` SQL, where we copy the table's structure along with the data in it.
	- Shallow copy is copying just the table structure but not the data, `CREATE OR REPLACE TABLE customers_shallow_copy LIKE customers;`.

- Difference between Temporary and Transient Tables:
	- `CREATE TABLE` will create tables with permanent life, whereas, `CREATE TEMPORARY TABLE AS` or `CREATE TRANSIENT TABLE AS` will create temporary and transient tables. The temporary tables will be gone once the UI session is killed, but the transient tables will be preserved across sessions but do not consume fail-safe storage.
	
	- Temporary table will exist only till the user's UI session is active and temporary table cannot be viewed or queried by other users.
	
	- Transient tables will exist until explicitly dropped and are visible to any user with the appropriate privileges. Transient tables have a lower level of data protection than permanent tables.

	- 1 day of retention data period by default, no fail-safe storage option available.

	- We can create a transient table from a temporary and a temporary table from a transient but using either of these two we cannot create a permanent table.
	
## Topic 5: Stage in Snowflake

- A Stage is a logical concept of a filesystem location that is external (AWS S3) or internal (For example, users can create their Stage) to Snowflake.

- A stage can be created using  `CREATE OR REPLACE STAGE {name} URL= {cloud_URL}` SQL in a worksheet after selecting the WH, DATABASE, Schema, and with required privileges.

- After creating an internal or external STAGE, we can use `LIST @{stage_name}` SQL to view all the stage files under that STAGE.

- Difference between Database tables and External tables?
	- *Database tables* point to the data inside a database.
	- *External tables* point to the data present in the files that exist in a staging area.
	- Data present in a database table can be exposed to CRUD operations but external tables are read-only tables.
	- External table's rows are created in JSON format with a key-value pair, where the key is the column name and the value is the row value.
	
- A created stage can be viewed similarly to a database and table using `SHOW STAGES LIKE '{stage_name}';`, this will return information like the database and schema in which the stage is created, URL of the stage, cloud in which it is stored, etc.

- Using the last_modified_date column values from the external stage, we can set up triggers to run ETL jobs to update data in external tables.

- An external table can be created using `create or replace external table {tbl_name} with location = @{stage_name} file_format = (type = csv) pattern = '.*{file_pattern}[.]csv';`.

- Once an external table is created, we can use `SELECT value:c1::float as {column_name} from ext_table;`. Here, we select all values from column one, cast them into float datatype, and alias the column.

## Topic 6: Views in Snowflake

- Snowflake views can be created using the `CREATE VIEW ...` SQL.

- Snowflake materialized views can be created using the `CREATE MATERIALIZED VIEW ...` SQL.

- Creating simple views in Snowflake and querying it will take a reasonable amount of time to return the output, in my case, it took 41s to return 2.5K rows. This issue can be tackled with the help of a materialized view. To create materialized views, we need at least an Enterprise edition.

- Difference between view and materialized view:
	- Materialized view takes more time to create but not querying, views are quicker to create but longer to query.
	- Views store the SQL DDL to fetch the data, whereas, materialized views store the actual data in them.
	- Normal views are queried, then the underlying SQL is queried to the user. That's the reason behind the wait time. The more complex the underlying query, the higher the time it takes to output the result set.
	- Normal views are recommended when creating a 1-to-1 copy of a table or while selecting just the active records from an SCD table.
	- Materialized views are recommended when creating views with complex and reusable logic. Materialized views run the query as soon as the view gets created and store the data in them and not just the SQL behind the data. This is why it takes some time when created for the first time but quicker when querying.
	
## Topic 7: Loading Data in and Extracting data out of Snowflake

### How to load delimited data from cloud storage?

#### External Stage
- To load delimited data from cloud storage, we will be creating an *External Stage* and using the COPY INTO command to load the data into a table.

- Why create an external stage?
	- In Snowflake, the External stage can be understood as a virtual location that exists inside Snowflake but refers to files present in an external storage like AWS S3, or Azure Blob Storage. 
	- The external stage itself doesn't hold any data files but it talks to external parties and lists the files that they might hold.
	- This is where the `LIST @your_stage_name` SQL comes in handy.
	- Even before trying to load the data, we can do a LIST SQL on the external stage that we created to confirm that Snowflake can talk with the external parties and read the files available. This will give us additional confidence to prove that Snowflake has all the read-access rights to fetch the data present elsewhere.

An alternative for creating an external stage is to use the S3 bucket's or Azure Blob storage's URL directly in your COPY INTO statement.

- The Sequence of actions will be in this order:
	- Create a Database, if one is not created already. For ETL purposes, always create transient databases, so that we can save some of our free credits.
	
	- Create a staging schema, this is advisable to segregate raw tables and transformed tables.
	
	- Create the target table using generic `CREATE TABLE ` SQL. As the database is a transient one, we don't need to create the table as a transient one, the properties will be inherited from the DB. To double-check this, use `SHOW DATABASES LIKE ''` and `SHOW TABLES LIKE ''` and look for the values under retention_time and options.
	
	- Create a FILE FORMAT. In Snowflake, a FILE FORMAT is an object that defines how to interpret and parse the contents of files when loading or unloading data. It specifies the file format properties such as field delimiters, record delimiters, character encoding, and other options. This can be later used in COPY INTO or COPY FROM statements and we don't have to rewrite all the properties again.
	
	- Create an external stage pointing to the cloud URL and FILE_FORMAT should be set to the FILE_FORMAT created in the above step.
	
	- Load the data into the target table using this SQL: `COPY INTO CREDIT_CARDS FROM @YOUR_STAGE;`. Your external stage might have multiple files, to load specific files, use `COPY INTO CREDIT_CARDS FROM @YOUR_STAGE/sub_dir/file_name.csv;`.
	
	- By executing the above-mentioned COPY INTO statement, you can see the status of the load, rows parsed and loaded, and total error is seen.
	
	- While doing a COPY INTO, Snowflake will use the target table's column data type to cast the value while loading and we cannot do an explicit casting in COPY INTO.
	
	- To check the contents of the TGT table, you can do either a `SELECT * ..` or `SELECT COUNT(*)` on your target table.

#### Internal Stage

- To load delimited data from local storage, we will be creating an *Internal Stage* and using the COPY INTO command to load the data into a table.

- Different type of internal stages:
	- User stage: 
		- Each user gets an user stage by default to store files.
		- Command to view the contents in an user stage: `LIST @~`
		- User stage is handy as a single user who is trying to load files into multiple table.
		- User stage cannot be altered or dropped.
		- Other user cannot view the contents in your stage and you cannot view other user's stage contents.
		- User stage doesn't support the use of FILE FORMAT, instead, while doing the COPY INTO statement you have to define them.
		
	- Table stage:
		- Each table gets a table stage by default to store files.
		- Command to view the contents in a table stage: `LIST @%table_name` 
		- Table stage can be accessed by multiple users but the contents in a table stage can be copied only to a single table.
		
	- Named Stage:
		- This stage should be created manually similar to external stage. Instead of providing the URL, here, we will be providing the information about the files, example, file format, delimiters, qouted data or not, etc.
		- Uploading files to an internal named stage can be done via SnowSQL or using GUI techniques.
		- Command to view the contents in an user stage: `LIST @{NAMED_STAGE}`
		
- Once the source files are placed in the named stage, use the `COPY INTO TABLENAME` SQL, if the file format wasn't mentioned during the time of named stage creation then we can mention them while doing a COPY INTO SQL.

- Once the data is loaded into the target table, it's advisable to do an `REMOVE @{NAMED_STAGE};` as storing file in named stage attract billing.

- Difference between an internal and external stage?
	- When creating a stage, if have you used an URL to specify the path of the files, then it is an *External Stage*, else it is an *Internal Stage*.
	- `SHOW STAGES LIKE'%STAGE'` SQL will list all the stage under current DB and schema, you can scroll towards your right in the result set to find the column called "Type". That column describes whether it is internal or extenal.
	- External stage mirrors the files present elsewhere outside of Snowflake.
	- Internal stage holds the files within Snowflake.
	- External stage doesn't attract additional billing but Internal stage does attract additional billing.

	
## Topic 8: IAM in Snowflake

### What means Identity?

- Identity talks about who you are?
- It's an one-time process and it is checked by "Authenticator" using your credentials.

### What means Authorization?

- Once Identity is approved, authorization process kicks in.
- It's an ongoing process and it is checked by "Authorizer" using RBAC.
- Your username and password matters only when you login for the first time, but the roles that are assigned to your user matters whenever you query or create a database object in Snowflake.
	- ACCOUNTADMIN has got the highest privileges within Snowflake.
	- SECURITYADMIN & USERADMIN are gate-keeping and enforcement roles.
	- SYSADMIN is the role to create Warehoused, DBs and Tables in Snowflake.
	
### What means Discretionary Access Control (DAC) in Snowflake?

Snowflake uses a combination of RBAC and DAC, when we create something, the ROLE we were using at the time we created it, is the role that OWNS it and not the user who created it.

### What means Custodial Oversight in Snowflake?

- A parent can enter a child's room and check if there's anything doggy, likewise, ACCOUNTADMIN can delete, rename or modify SECURITYADMIN created objects. 
- Each role in the upper tree will have access to lower tree's role objects but not the other way around.
