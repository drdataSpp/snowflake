USE SCHEMA D1.S1;

--------------------------------------------------------------------------------
-- STEP 1: Create the staging table
--------------------------------------------------------------------------------
CREATE OR ALTER TRANSIENT TABLE stage__customer (
    CUSTOMER_ID         NUMBER(38,0)   NOT NULL,        
    CUSTOMER_NAME       STRING         NOT NULL,        
    CUSTOMER_EMAIL      STRING         NOT NULL,        
    CUSTOMER_SEGMENT    STRING         NOT NULL,        
    CUSTOMER_REGION     STRING         NOT NULL,        
    PRIMARY KEY (CUSTOMER_ID)
);

--------------------------------------------------------------------------------
-- STEP 2: Create a stream on the staging table
--------------------------------------------------------------------------------
CREATE OR REPLACE STREAM s_customer_changes ON TABLE stage__customer;

--------------------------------------------------------------------------------
-- STEP 3: Create the SCD Type 2 target table
--------------------------------------------------------------------------------
CREATE OR ALTER TRANSIENT TABLE perm__customer (
    CUSTOMER_ID             NUMBER(38,0)   NOT NULL,        
    CUSTOMER_NAME           STRING         NOT NULL,        
    CUSTOMER_EMAIL          STRING         NOT NULL,        
    CUSTOMER_SEGMENT        STRING         NOT NULL,        
    CUSTOMER_REGION         STRING         NOT NULL,        
    SCD_RECORD_START_DT     DATE           NOT NULL,
    SCD_RECORD_END_DT       DATE           NOT NULL,
    SCD_RECORD_DELETED_FLAG BOOLEAN        NOT NULL,
    PRIMARY KEY (CUSTOMER_ID)
);

--------------------------------------------------------------------------------
-- STEP 4: Initial Insert into the staging table (performed by ETL)
--------------------------------------------------------------------------------
INSERT INTO stage__customer (
    CUSTOMER_ID, CUSTOMER_NAME, CUSTOMER_EMAIL, CUSTOMER_SEGMENT, CUSTOMER_REGION
) VALUES (
    1001, 'Jane Doe', 'jane.doe@example.com', 'Consumer', 'APAC'
);

--------------------------------------------------------------------------------
-- STEP 5: Verify inserted rows in stream
--------------------------------------------------------------------------------
SELECT * 
FROM s_customer_changes
WHERE METADATA$ACTION = 'INSERT' AND METADATA$ISUPDATE = FALSE;

--------------------------------------------------------------------------------
-- STEP 6: Perform SCD Type 2 Merge from staging stream to target
--------------------------------------------------------------------------------
MERGE INTO perm__customer tgt
USING s_customer_changes s_cust
ON tgt.CUSTOMER_ID = s_cust.CUSTOMER_ID 
   AND tgt.CUSTOMER_NAME = s_cust.CUSTOMER_NAME
   AND tgt.CUSTOMER_EMAIL = s_cust.CUSTOMER_EMAIL
   AND tgt.CUSTOMER_SEGMENT = s_cust.CUSTOMER_SEGMENT
   AND tgt.CUSTOMER_REGION = s_cust.CUSTOMER_REGION
   /* This is to fetch the latest inserted/ updated records */
   AND tgt.SCD_RECORD_END_DT = '9000-12-31'
   AND tgt.SCD_RECORD_DELETED_FLAG = FALSE

-- Soft Delete (Hard delete from staging)
WHEN MATCHED AND s_cust.METADATA$ACTION = 'DELETE' AND s_cust.METADATA$ISUPDATE = FALSE THEN
    UPDATE SET tgt.SCD_RECORD_DELETED_FLAG = TRUE

-- Update old record (when updated in staging)
WHEN MATCHED AND s_cust.METADATA$ACTION = 'DELETE' AND s_cust.METADATA$ISUPDATE = TRUE THEN
    UPDATE SET tgt.SCD_RECORD_END_DT = CURRENT_DATE

-- Insert new record (initial insert)
WHEN NOT MATCHED AND s_cust.METADATA$ACTION = 'INSERT' AND s_cust.METADATA$ISUPDATE = FALSE THEN
    INSERT (CUSTOMER_ID, CUSTOMER_NAME, CUSTOMER_EMAIL, CUSTOMER_SEGMENT, CUSTOMER_REGION,
            SCD_RECORD_START_DT, SCD_RECORD_END_DT, SCD_RECORD_DELETED_FLAG)
    VALUES (s_cust.CUSTOMER_ID, s_cust.CUSTOMER_NAME, s_cust.CUSTOMER_EMAIL, s_cust.CUSTOMER_SEGMENT, s_cust.CUSTOMER_REGION,
            CURRENT_DATE, TO_DATE('9000-12-31'), FALSE)

-- Insert updated record (after update in staging)
WHEN NOT MATCHED AND s_cust.METADATA$ACTION = 'INSERT' AND s_cust.METADATA$ISUPDATE = TRUE THEN
    INSERT (CUSTOMER_ID, CUSTOMER_NAME, CUSTOMER_EMAIL, CUSTOMER_SEGMENT, CUSTOMER_REGION,
            SCD_RECORD_START_DT, SCD_RECORD_END_DT, SCD_RECORD_DELETED_FLAG)
    VALUES (s_cust.CUSTOMER_ID, s_cust.CUSTOMER_NAME, s_cust.CUSTOMER_EMAIL, s_cust.CUSTOMER_SEGMENT, s_cust.CUSTOMER_REGION,
            CURRENT_DATE, TO_DATE('9000-12-31'), FALSE);

--------------------------------------------------------------------------------
-- STEP 7: View Active Records
--------------------------------------------------------------------------------
SELECT * 
FROM perm__customer
WHERE SCD_RECORD_END_DT = '9000-12-31' AND SCD_RECORD_DELETED_FLAG = FALSE;

--------------------------------------------------------------------------------
-- STEP 8: Insert New Records and Update One
--------------------------------------------------------------------------------
INSERT INTO stage__customer VALUES (1002, 'John Smith', 'john.smith@example.com', 'Corporate', 'EMEA');
INSERT INTO stage__customer VALUES (1003, 'Emily Davis', 'emily.davis@example.com', 'Small Business', 'AMER');

UPDATE stage__customer
SET CUSTOMER_NAME = 'Jane A. Doe',
    CUSTOMER_EMAIL = 'jane.a.doe@example.com',
    CUSTOMER_SEGMENT = 'Consumer Plus',
    CUSTOMER_REGION = 'APAC-South'
WHERE CUSTOMER_ID = 1001;

--------------------------------------------------------------------------------
-- STEP 9: Merge again (repeat merge logic)
--------------------------------------------------------------------------------
-- (Repeat same MERGE SQL as in STEP 6)

/* To see only active rows */

SELECT * 
FROM perm__customer
WHERE SCD_RECORD_END_DT = '9000-12-31' AND SCD_RECORD_DELETED_FLAG = FALSE;

/* To see all historical records */

SELECT * 
FROM perm__customer
ORDER BY 1, 6, 7;

/* Update the same record again and rerun step 6 merge */

UPDATE stage__customer
SET CUSTOMER_NAME = 'Jane Don Bosco',
    CUSTOMER_EMAIL = 'jane.a.doe@example.com',
    CUSTOMER_SEGMENT = 'Consumer Plus',
    CUSTOMER_REGION = 'APAC-EAST'
WHERE CUSTOMER_ID = 1001;

--------------------------------------------------------------------------------
-- STEP 10: Delete a record from staging (soft delete)
--------------------------------------------------------------------------------
DELETE FROM stage__customer WHERE CUSTOMER_ID = 1001;

--------------------------------------------------------------------------------
-- STEP 11: Final Merge to reflect deletion
--------------------------------------------------------------------------------
-- (Repeat same MERGE SQL as in STEP 6)

/* To see only active rows */

SELECT * 
FROM perm__customer
WHERE SCD_RECORD_END_DT = '9000-12-31' AND SCD_RECORD_DELETED_FLAG = 0;

/* To see all historical records */

SELECT * 
FROM perm__customer
ORDER BY 1, 6, 7;