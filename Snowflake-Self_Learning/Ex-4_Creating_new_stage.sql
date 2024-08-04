-- OOE: 1

CREATE OR REPLACE STAGE sfuser_ext_stage
URL='s3://snowflake-cookbook/Chapter02/r4/';

-- OOE: 2

-- LIST command will list all the stage files under that Stage.
LIST @SFUSER_EXT_STAGE;

-- OOE: 3

--Creating an external table using the data from the above stage
create or replace external table ext_card_data
with location = @sfuser_ext_stage/csv
file_format = (type = csv)
pattern = '.*headless[.]csv';

-- OOE: 4

-- Querying data in column and row format as they're in JSON format

select 
	value:c3::float as card_sum, --selecting column 3 as card_sum, casting the values into float datatype
	value:c2::string as period --selecting column 2 as period, casting the values into string datatype
from ext_card_data;


--Creating an internal named stage

CREATE FILE FORMAT PIPE_DELIM
TYPE = CSV
FIELD_DELIMITER = '|'
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
SKIP_HEADER = 1
DATE_FORMAT = 'YYYY-MM-DD';

CREATE OR REPLACE STAGE CUSTOMER_STAGE
FILE_FORMAT = PIPE_DELIM; --Here, if you provide an URL, then it is an external stage.