import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

## Initialize Glue Context
glueContext = GlueContext(SparkContext.getOrCreate())

## Load the Data
datasource0 = glueContext.create_dynamic_frame.from_catalog(
    database = "nsw_property_data",
    table_name = "your_s3_data_table"
)

## Transformations (Add, Remove, Filter Columns)
datasource0 = datasource0.filter(lambda x: x["price"] is not None)

## Load to Redshift
glueContext.write_dynamic_frame.from_catalog(
    frame = datasource0,
    database = "redshift",
    table_name = "nsw_properties",
    redshift_tmp_dir = "s3://realestate1799/temp/",
    transformation_ctx = "datasource0"
)
