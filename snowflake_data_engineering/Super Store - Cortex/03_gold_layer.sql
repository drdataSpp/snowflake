-- =============================================================================
-- SUPER_STORE DATA MART - CTAS STATEMENTS (GOLD LAYER)
-- =============================================================================
-- This script creates the Data Mart tables (Facts and Dimensions)
-- in the SUPER_STORE.GOLD schema from the SUPER_STORE.SILVER (Data Vault) tables.
--
-- Execution Order:
-- 1. Dimension Tables
-- 2. Fact Tables
-- =============================================================================

-- Ensure the GOLD schema exists
CREATE SCHEMA IF NOT EXISTS SUPER_STORE.GOLD;


-- =============================================================================
-- STEP 1: CREATE DIMENSION TABLES
-- Dimensions store descriptive attributes.
-- =============================================================================

-- DIM_CUSTOMER: Customer Dimension
CREATE OR REPLACE TABLE SUPER_STORE.GOLD.DIM_CUSTOMER AS
SELECT
    HC.HUB_CUSTOMER_KEY AS CUSTOMER_KEY,
    HC.CUSTOMER_ID,
    SCD."Customer Name" AS CUSTOMER_NAME,
    SCD."Segment" AS SEGMENT,
    SCD.LOAD_DATE AS LOAD_DATE
FROM SUPER_STORE.SILVER.HUB_CUSTOMER HC
JOIN SUPER_STORE.SILVER.SAT_CUSTOMER_DETAILS SCD
    ON HC.HUB_CUSTOMER_KEY = SCD.HUB_CUSTOMER_KEY;


-- DIM_PRODUCT: Product Dimension
CREATE OR REPLACE TABLE SUPER_STORE.GOLD.DIM_PRODUCT AS
SELECT
    HP.HUB_PRODUCT_KEY AS PRODUCT_KEY,
    HP.PRODUCT_ID,
    SPD."Product Name" AS PRODUCT_NAME,
    SPD."Category" AS CATEGORY,
    SPD."Sub-Category" AS SUB_CATEGORY,
    SPD.LOAD_DATE AS LOAD_DATE
FROM SUPER_STORE.SILVER.HUB_PRODUCT HP
JOIN SUPER_STORE.SILVER.SAT_PRODUCT_DETAILS SPD
    ON HP.HUB_PRODUCT_KEY = SPD.HUB_PRODUCT_KEY;


-- DIM_ORDER: Order Dimension
CREATE OR REPLACE TABLE SUPER_STORE.GOLD.DIM_ORDER AS
SELECT
    HO.HUB_ORDER_KEY AS ORDER_KEY,
    HO.ORDER_ID,
    SOD."Order Date" AS ORDER_DATE,
    SOD."Ship Date" AS SHIP_DATE,
    SOD."Ship Mode" AS SHIP_MODE,
    SOD.LOAD_DATE AS LOAD_DATE
FROM SUPER_STORE.SILVER.HUB_ORDER HO
JOIN SUPER_STORE.SILVER.SAT_ORDER_DETAILS SOD
    ON HO.HUB_ORDER_KEY = SOD.HUB_ORDER_KEY;


-- DIM_GEOGRAPHY: Geography Dimension
CREATE OR REPLACE TABLE SUPER_STORE.GOLD.DIM_GEOGRAPHY AS
SELECT
    HG.HUB_GEOGRAPHY_KEY AS GEOGRAPHY_KEY,
    HG.COUNTRY,
    HG.STATE,
    HG.CITY,
    HG.POSTAL_CODE,
    SGD."Region" AS REGION,
    SGD.LOAD_DATE AS LOAD_DATE
FROM SUPER_STORE.SILVER.HUB_GEOGRAPHY HG
JOIN SUPER_STORE.SILVER.SAT_GEOGRAPHY_DETAILS SGD
    ON HG.HUB_GEOGRAPHY_KEY = SGD.HUB_GEOGRAPHY_KEY;


-- =============================================================================
-- STEP 2: CREATE FACT TABLE
-- Fact tables store the measures and foreign keys to dimensions.
-- =============================================================================

-- FCT_ORDER_SALES: Fact table for sales transactions
CREATE OR REPLACE TABLE SUPER_STORE.GOLD.FCT_ORDER_SALES AS
SELECT
    LOD.LINK_ORDER_DETAIL_KEY AS ORDER_DETAIL_KEY, -- Primary key for the fact table (optional, but good for tracking individual line items)
    LOD.HUB_ORDER_KEY AS ORDER_KEY,
    LOD.HUB_CUSTOMER_KEY AS CUSTOMER_KEY,
    LOD.HUB_PRODUCT_KEY AS PRODUCT_KEY,
    LOD.HUB_GEOGRAPHY_KEY AS GEOGRAPHY_KEY,
    SOTD."Sales" AS SALES,
    SOTD."Quantity" AS QUANTITY,
    SOTD."Discount" AS DISCOUNT,
    SOTD."Profit" AS PROFIT,
    SOTD.LOAD_DATE AS LOAD_DATE,
    SOTD.RECORD_SOURCE AS RECORD_SOURCE
FROM SUPER_STORE.SILVER.LINK_ORDER_DETAIL LOD
JOIN SUPER_STORE.SILVER.SAT_ORDER_TRANSACTION_DETAILS SOTD
    ON LOD.LINK_ORDER_DETAIL_KEY = SOTD.LINK_ORDER_DETAIL_KEY;