/* 

Exercise 7 - Snowflake Time Travel Feature

*/

/* 
	CREATING TABLE AND INSERTING MOCK DATA
*/
USE DATABASE NON_PROD; -- This DB has data_rentention set to 1 day, schema and tables under NON_PROD will follow the same.
USE SCHEMA QA;

--CREATING A TABLE
CREATE OR REPLACE TABLE QA.CUST (
    Customer_ID VARCHAR(50),
    Gender VARCHAR(10),
    Age INT,
    Annual_Income DECIMAL(18, 2)
);

SHOW TABLES LIKE '%CUST%';
--DATA RETENTION = 1 DAY & NON-TRANSIENT

--INSERTING DATA INTO QA CUST TABLE
INSERT INTO CUST (Customer_ID, Gender, Age, Annual_Income)
VALUES 
    ('1001', 'Male', 35, 75000.00),
    ('1002', 'Female', 28, 65000.00),
    ('1003', 'Male', 45, 90000.00),
    ('1004', 'Female', 42, 80000.00),
    ('1005', 'Male', 30, 70000.00);


SELECT * FROM QA.CUST;
SELECT COUNT(*) FROM QA.CUST; --5 ROWS


/* 
	TIME TRAVEL
*/


--Now let's update the age column to 60 for all rows, in reality, this might be a human error of not adding a where clause on the customer_id column to specify the exact record

UPDATE QA.CUST
SET Age = 60; --5 rows updated.

SELECT DISTINCT AGE -- ALL 60
FROM QA.CUST; 

-- DIFFERENT WAYS TO TIME TRAVEL IN SNOWFLAKE:

-- METHOD 1: TIMESTAMP

SELECT CURRENT_TIME();

SELECT * FROM QA.CUST AT(TIMESTAMP => 'Sun, 18 Feb 2024 05:27:00 -0001'::timestamp_tz);
--In the above statement, I have pasted the timestamp before executing the update statement.


-- METHOD 2: OFFSET

SELECT * FROM QA.CUST AT(OFFSET => -60*8);
--In the above statement, I have added the time difference between the update statement and the current time, i.e., 8 minutes
--Here 60 denotes seconds, minus denotes past time, and 8 denotes minutes. We are time-traveling back 8 minutes


--METHOD 3: QUERY ID

SELECT * FROM QA.CUST BEFORE(STATEMENT => '01b26963-0001-1b5a-0000-d63d000150ca');
--In the above statement, I have pasted the query ID that performed the UPDATE SQL to go back in time.
--Query ID can be found under Monitoring > Query History


/* 
	CLONING TABLE WITH CORRECT DATA USING TIME-TRAVEL
*/

--CLONING QA CUST TABLE WITH CORRECT AGE VALUES
CREATE OR REPLACE TABLE QA.CUST_CLONE AS
SELECT * FROM QA.CUST AT(OFFSET => -60*8);

-- Cloning is similar to Deep copy but using time travel feature.

SELECT * FROM QA.CUST_CLONE;


/* 
	DROP & UN-DROP Table
*/

DROP TABLE QA.CUST_CLONE;

--We cannot recreate a dropped table using AT statement:
SELECT * FROM QA.CUST_CLONE BEFORE(STATEMENT => '01b26976-0001-1b40-0000-d63d0001617e');

--Error: Object 'NON_PROD.QA.CUST_CLONE' does not exist or not authorized.

--Recreate SQL:
UNDROP TABLE QA.CUST_CLONE;

--Result: Table CUST_CLONE successfully restored.