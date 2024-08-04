--Creating a named stage to land source files used for dimensional modeling

USE WAREHOUSE ETL_WH;
USE DATABASE DEV;
USE SCHEMA RAW;


--Creating CSV file format
CREATE OR REPLACE FILE FORMAT CSV_SALES_FORMAT
TYPE = CSV
FIELD_DELIMITER = ','
SKIP_HEADER = 1
DATE_FORMAT = 'MM/DD/YYYY';


--Creating a new named stage
CREATE OR REPLACE STAGE CSV_STAGE
FILE_FORMAT = CSV_SALES_FORMAT;


--Moved source file using GUI
LIST @CSV_STAGE;


--Creating a table to store raw data
CREATE TABLE RAW.Sales (
    Invoice_ID VARCHAR(50),
    Branch VARCHAR(10),
    City VARCHAR(50),
    Customer_type VARCHAR(10),
    Gender VARCHAR(10),
    Product_line VARCHAR(100),
    Unit_price FLOAT,
    Quantity INT,
    Tax_Rate FLOAT,
    Total FLOAT,
    Date_of_Purchase DATE,
    Time_of_Purchase TIME,
    Payment VARCHAR(50),
    COGS FLOAT,
    gross_margin_percentage FLOAT,
    gross_income FLOAT,
    Rating FLOAT
);


--Inserting Data from the named stage
COPY INTO RAW.Sales
FROM @CSV_STAGE;


--Checking the loaded data
SELECT * FROM RAW.Sales
LIMIT 15;

SELECT COUNT(*) FROM SALES; --1000 ROWS