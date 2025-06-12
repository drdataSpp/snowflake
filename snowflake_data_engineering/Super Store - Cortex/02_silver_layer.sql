USE ROLE SYSADMIN;

-- Set the context for the session
USE SCHEMA SUPER_STORE.SILVER;

-- =============================================================================
-- SUPER_STORE DATA VAULT - CTAS STATEMENTS
-- =============================================================================
-- This script creates the Data Vault 2.0 tables (Hubs, Links, Satellites)
-- in the SUPER_STORE.SILVER schema from the SUPER_STORE.BRONZE.SUPER_STORE_SALES table.
--
-- Execution Order:
-- 1. Hubs
-- 2. Links
-- 3. Satellites
-- =============================================================================

-- =============================================================================
-- STEP 1: CREATE HUB TABLES
-- Hubs store the unique business keys.
-- =============================================================================

-- HUB_CUSTOMER: Stores unique customer identifiers
CREATE OR REPLACE TABLE SUPER_STORE.SILVER.HUB_CUSTOMER AS
SELECT
    SHA1(TRIM(CAST("Customer ID" AS VARCHAR))) AS HUB_CUSTOMER_KEY, -- Surrogate Key
    "Customer ID" AS CUSTOMER_ID, -- Business Key
    CURRENT_TIMESTAMP() AS LOAD_DATE,
    'SUPER_STORE_SALES' AS RECORD_SOURCE
FROM (
    SELECT DISTINCT "Customer ID"
    FROM SUPER_STORE.BRONZE.SUPER_STORE_SALES
    WHERE "Customer ID" IS NOT NULL
);

-- HUB_PRODUCT: Stores unique product identifiers
CREATE OR REPLACE TABLE SUPER_STORE.SILVER.HUB_PRODUCT AS
SELECT
    SHA1(TRIM(CAST("Product ID" AS VARCHAR))) AS HUB_PRODUCT_KEY, -- Surrogate Key
    "Product ID" AS PRODUCT_ID, -- Business Key
    CURRENT_TIMESTAMP() AS LOAD_DATE,
    'SUPER_STORE_SALES' AS RECORD_SOURCE
FROM (
    SELECT DISTINCT "Product ID"
    FROM SUPER_STORE.BRONZE.SUPER_STORE_SALES
    WHERE "Product ID" IS NOT NULL
);

-- HUB_ORDER: Stores unique order identifiers
CREATE OR REPLACE TABLE SUPER_STORE.SILVER.HUB_ORDER AS
SELECT
    SHA1(TRIM(CAST("Order ID" AS VARCHAR))) AS HUB_ORDER_KEY, -- Surrogate Key
    "Order ID" AS ORDER_ID, -- Business Key
    CURRENT_TIMESTAMP() AS LOAD_DATE,
    'SUPER_STORE_SALES' AS RECORD_SOURCE
FROM (
    SELECT DISTINCT "Order ID"
    FROM SUPER_STORE.BRONZE.SUPER_STORE_SALES
    WHERE "Order ID" IS NOT NULL
);

-- HUB_GEOGRAPHY: Stores unique geographic locations
CREATE OR REPLACE TABLE SUPER_STORE.SILVER.HUB_GEOGRAPHY AS
SELECT
    SHA1(UPPER(TRIM(CONCAT_WS('||', COALESCE(CAST("Country" AS VARCHAR), 'N/A'), COALESCE(CAST("State" AS VARCHAR), 'N/A'), COALESCE(CAST("City" AS VARCHAR), 'N/A'), COALESCE(CAST("Postal Code" AS VARCHAR), 'N/A'))))) AS HUB_GEOGRAPHY_KEY, -- Surrogate Key
    "Country" AS COUNTRY, -- Component of Business Key
    "State" AS STATE, -- Component of Business Key
    "City" AS CITY, -- Component of Business Key
    "Postal Code" AS POSTAL_CODE, -- Component of Business Key
    CURRENT_TIMESTAMP() AS LOAD_DATE,
    'SUPER_STORE_SALES' AS RECORD_SOURCE
FROM (
    SELECT DISTINCT "Country", "State", "City", "Postal Code"
    FROM SUPER_STORE.BRONZE.SUPER_STORE_SALES
);


-- =============================================================================
-- STEP 2: CREATE LINK TABLE
-- Links store the relationships between Hubs.
-- =============================================================================

-- LINK_ORDER_DETAIL: Connects Orders, Customers, Products, and Geography for each transaction line
CREATE OR REPLACE TABLE SUPER_STORE.SILVER.LINK_ORDER_DETAIL AS
SELECT
    SHA1(CONCAT_WS('||', HUB_ORDER_KEY, HUB_CUSTOMER_KEY, HUB_PRODUCT_KEY, HUB_GEOGRAPHY_KEY)) AS LINK_ORDER_DETAIL_KEY,
    H_ORD.HUB_ORDER_KEY,
    H_CUST.HUB_CUSTOMER_KEY,
    H_PROD.HUB_PRODUCT_KEY,
    H_GEO.HUB_GEOGRAPHY_KEY,
    S.LOAD_DATE,
    S.RECORD_SOURCE
FROM (
    SELECT
        "Row ID", -- To ensure uniqueness per line item
        "Order ID",
        "Customer ID",
        "Product ID",
        "Country",
        "State",
        "City",
        "Postal Code",
        CURRENT_TIMESTAMP() AS LOAD_DATE,
        'SUPER_STORE_SALES' AS RECORD_SOURCE
    FROM SUPER_STORE.BRONZE.SUPER_STORE_SALES
) S
LEFT JOIN SUPER_STORE.SILVER.HUB_ORDER H_ORD
    ON S."Order ID" = H_ORD.ORDER_ID
LEFT JOIN SUPER_STORE.SILVER.HUB_CUSTOMER H_CUST
    ON S."Customer ID" = H_CUST.CUSTOMER_ID
LEFT JOIN SUPER_STORE.SILVER.HUB_PRODUCT H_PROD
    ON S."Product ID" = H_PROD.PRODUCT_ID
LEFT JOIN SUPER_STORE.SILVER.HUB_GEOGRAPHY H_GEO
    ON S."Country" = H_GEO.COUNTRY
    AND S."State" = H_GEO.STATE
    AND S."City" = H_GEO.CITY
    AND S."Postal Code" = H_GEO.POSTAL_CODE;

-- =============================================================================
-- STEP 3: CREATE SATELLITE TABLES
-- Satellites store the descriptive attributes for Hubs and Links.
-- They also track historical changes.
-- =============================================================================

-- SAT_CUSTOMER_DETAILS: Descriptive attributes for customers
CREATE OR REPLACE TABLE SUPER_STORE.SILVER.SAT_CUSTOMER_DETAILS AS
SELECT
    H_CUST.HUB_CUSTOMER_KEY,
    S."Customer Name",
    S."Segment",
    SHA1(UPPER(TRIM(CONCAT_WS('||', COALESCE(CAST(S."Customer Name" AS VARCHAR), 'N/A'), COALESCE(CAST(S."Segment" AS VARCHAR), 'N/A'))))) AS HASH_DIFF,
    S.LOAD_DATE,
    S.RECORD_SOURCE
FROM (
    SELECT DISTINCT "Customer ID", "Customer Name", "Segment", CURRENT_TIMESTAMP() as LOAD_DATE, 'SUPER_STORE_SALES' as RECORD_SOURCE
    FROM SUPER_STORE.BRONZE.SUPER_STORE_SALES
) S
JOIN SUPER_STORE.SILVER.HUB_CUSTOMER H_CUST
    ON S."Customer ID" = H_CUST.CUSTOMER_ID;


-- SAT_PRODUCT_DETAILS: Descriptive attributes for products
CREATE OR REPLACE TABLE SUPER_STORE.SILVER.SAT_PRODUCT_DETAILS AS
SELECT
    H_PROD.HUB_PRODUCT_KEY,
    S."Product Name",
    S."Category",
    S."Sub-Category",
    SHA1(UPPER(TRIM(CONCAT_WS('||', COALESCE(CAST(S."Product Name" AS VARCHAR), 'N/A'), COALESCE(CAST(S."Category" AS VARCHAR), 'N/A'), COALESCE(CAST(S."Sub-Category" AS VARCHAR), 'N/A'))))) AS HASH_DIFF,
    S.LOAD_DATE,
    S.RECORD_SOURCE
FROM (
    SELECT DISTINCT "Product ID", "Product Name", "Category", "Sub-Category", CURRENT_TIMESTAMP() as LOAD_DATE, 'SUPER_STORE_SALES' as RECORD_SOURCE
    FROM SUPER_STORE.BRONZE.SUPER_STORE_SALES
) S
JOIN SUPER_STORE.SILVER.HUB_PRODUCT H_PROD
    ON S."Product ID" = H_PROD.PRODUCT_ID;


-- SAT_ORDER_DETAILS: Descriptive attributes for orders
CREATE OR REPLACE TABLE SUPER_STORE.SILVER.SAT_ORDER_DETAILS AS
SELECT
    H_ORD.HUB_ORDER_KEY,
    S."Order Date",
    S."Ship Date",
    S."Ship Mode",
    SHA1(UPPER(TRIM(CONCAT_WS('||', COALESCE(CAST(S."Order Date" AS VARCHAR), 'N/A'), COALESCE(CAST(S."Ship Date" AS VARCHAR), 'N/A'), COALESCE(CAST(S."Ship Mode" AS VARCHAR), 'N/A'))))) AS HASH_DIFF,
    S.LOAD_DATE,
    S.RECORD_SOURCE
FROM (
    SELECT DISTINCT "Order ID", "Order Date", "Ship Date", "Ship Mode", CURRENT_TIMESTAMP() as LOAD_DATE, 'SUPER_STORE_SALES' as RECORD_SOURCE
    FROM SUPER_STORE.BRONZE.SUPER_STORE_SALES
) S
JOIN SUPER_STORE.SILVER.HUB_ORDER H_ORD
    ON S."Order ID" = H_ORD.ORDER_ID;


-- SAT_GEOGRAPHY_DETAILS: Descriptive attributes for geographic locations
CREATE OR REPLACE TABLE SUPER_STORE.SILVER.SAT_GEOGRAPHY_DETAILS AS
SELECT
    H_GEO.HUB_GEOGRAPHY_KEY,
    S."Region",
    SHA1(UPPER(TRIM(COALESCE(CAST(S."Region" AS VARCHAR), 'N/A')))) AS HASH_DIFF,
    S.LOAD_DATE,
    S.RECORD_SOURCE
FROM (
    SELECT DISTINCT "Country", "State", "City", "Postal Code", "Region", CURRENT_TIMESTAMP() as LOAD_DATE, 'SUPER_STORE_SALES' as RECORD_SOURCE
    FROM SUPER_STORE.BRONZE.SUPER_STORE_SALES
) S
JOIN SUPER_STORE.SILVER.HUB_GEOGRAPHY H_GEO
    ON S."Country" = H_GEO.COUNTRY
    AND S."State" = H_GEO.STATE
    AND S."City" = H_GEO.CITY
    AND S."Postal Code" = H_GEO.POSTAL_CODE;

-- SAT_ORDER_TRANSACTION_DETAILS: Transactional attributes for the order detail link
CREATE OR REPLACE TABLE SUPER_STORE.SILVER.SAT_ORDER_TRANSACTION_DETAILS AS
SELECT
    LNK.LINK_ORDER_DETAIL_KEY,
    S."Sales",
    S."Quantity",
    S."Discount",
    S."Profit",
    SHA1(UPPER(TRIM(CONCAT_WS('||', COALESCE(CAST(S."Sales" AS VARCHAR), 'N/A'), COALESCE(CAST(S."Quantity" AS VARCHAR), 'N/A'), COALESCE(CAST(S."Discount" AS VARCHAR), 'N/A'), COALESCE(CAST(S."Profit" AS VARCHAR), 'N/A'))))) AS HASH_DIFF,
    S.LOAD_DATE,
    S.RECORD_SOURCE
FROM (
    SELECT
        "Row ID", -- For joining
        "Order ID",
        "Customer ID",
        "Product ID",
        "Country", "State", "City", "Postal Code", -- For joining to get Link key
        "Sales",
        "Quantity",
        "Discount",
        "Profit",
        CURRENT_TIMESTAMP() as LOAD_DATE,
        'SUPER_STORE_SALES' as RECORD_SOURCE
    FROM SUPER_STORE.BRONZE.SUPER_STORE_SALES
) S
JOIN SUPER_STORE.SILVER.HUB_ORDER H_ORD ON S."Order ID" = H_ORD.ORDER_ID
JOIN SUPER_STORE.SILVER.HUB_CUSTOMER H_CUST ON S."Customer ID" = H_CUST.CUSTOMER_ID
JOIN SUPER_STORE.SILVER.HUB_PRODUCT H_PROD ON S."Product ID" = H_PROD.PRODUCT_ID
JOIN SUPER_STORE.SILVER.HUB_GEOGRAPHY H_GEO
    ON S."Country" = H_GEO.COUNTRY
    AND S."State" = H_GEO.STATE
    AND S."City" = H_GEO.CITY
    AND S."Postal Code" = H_GEO.POSTAL_CODE
JOIN SUPER_STORE.SILVER.LINK_ORDER_DETAIL LNK
    ON H_ORD.HUB_ORDER_KEY = LNK.HUB_ORDER_KEY
    AND H_CUST.HUB_CUSTOMER_KEY = LNK.HUB_CUSTOMER_KEY
    AND H_PROD.HUB_PRODUCT_KEY = LNK.HUB_PRODUCT_KEY
    AND H_GEO.HUB_GEOGRAPHY_KEY = LNK.HUB_GEOGRAPHY_KEY;
