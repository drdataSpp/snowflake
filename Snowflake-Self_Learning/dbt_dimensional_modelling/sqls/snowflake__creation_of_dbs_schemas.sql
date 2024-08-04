USE WAREHOUSE ETL_WH;

--CREATING A NEW DB

CREATE OR REPLACE DATABASE DEV
COMMENT = 'This DB will be used to try out DBT + SF ;)';


--CREATING 5 NEW SCHEMAS
CREATE OR REPLACE SCHEMA RAW
COMMENT = 'Source data is stored as it is, no major txfms';

CREATE OR REPLACE SCHEMA SURROGATE_KEYS
COMMENT = 'Surrogate Key created on top of source data';

CREATE OR REPLACE SCHEMA SURROGATE_KEYS
COMMENT = 'Surrogate Key created on top of source data';

CREATE OR REPLACE SCHEMA DIMENSIONS
COMMENT = 'Stores Dimension Views for Fact tables';

CREATE OR REPLACE SCHEMA FACT
COMMENT = 'Stores Fact tables';