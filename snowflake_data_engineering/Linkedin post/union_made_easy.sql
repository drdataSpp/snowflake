-- UNION with different column counts

WITH nz_customers AS (
    SELECT 1 AS customer_id, 'Alice Kauri' AS customer_name, 'Wellington' AS city, 'NZ' AS country
    UNION ALL
    SELECT 2, 'Brent Tane', 'Auckland', 'NZ'
),
aus_customers AS (
    SELECT 3 AS customer_id, 'Daniel Smith' AS customer_name, 'Sydney' AS city, 'AUS' AS country, 'Gold' AS membership_level
    UNION ALL
    SELECT 4, 'Ella Brown', 'Melbourne', 'AUS', 'Silver'
)

-- ❌ Fails: invalid number of result columns for set operator input branches, expected 4, got 5 in branch 2
SELECT * FROM nz_customers
UNION ALL
SELECT * FROM aus_customers;

-- ✅ Works: aligns columns by name, fills missing ones with NULL
SELECT * FROM nz_customers
UNION ALL BY NAME
SELECT * FROM aus_customers;

-- UNION BY NAME with different column names (customer_name vs cust_name)

WITH nz_customers AS (
    SELECT 1 AS customer_id, 'Alice Kauri' AS customer_name, 'Wellington' AS city, 'NZ' AS country
    UNION ALL
    SELECT 2, 'Brent Tane', 'Auckland', 'NZ'
),
aus_customers AS (
    SELECT 3 AS customer_id, 'Daniel Smith' AS cust_name, 'Sydney' AS city, 'AUS' AS country, 'Gold' AS membership_level
    UNION ALL
    SELECT 4, 'Ella Brown', 'Melbourne', 'AUS', 'Silver'
)

-- Mismatched column names → separate output columns
SELECT * FROM nz_customers
UNION ALL BY NAME
SELECT * FROM aus_customers;

/*
🧾 Output:

CUSTOMER_NAME   CUST_NAME
-------------   ----------
Alice Kauri     NULL
Brent Tane      NULL
NULL            Daniel Smith
NULL            Ella Brown
*/
