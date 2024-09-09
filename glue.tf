resource "aws_glue_catalog_database" "glue_catalog_database" {
    name = "nsw_data"
}

resource "aws_glue_crawler" "glue_crawler" {
    database_name = aws_glue_catalog_database.glue_catalog_database.name
    name = "nsw-crawler"
    role = aws_iam_role.iam_for_glue.arn
    s3_target {
        path = "s3://realestate1799"
    }
}

#create redshift catalog database
resource "aws_glue_catalog_database" "redshift_catalog_database" {
  name = "rcd"
}
#create redshift to glue crawler
resource "aws_glue_crawler" "redshift_crawler" {
  database_name = "rcd"
  name          = "rgc"
  role          = aws_iam_role.iam_for_glue.arn
  jdbc_target {
    connection_name = aws_glue_connection.glue_jdbc_conn.name
    path            = "dev/public/nsw_properties" #db schema and table name
  }
}


resource "aws_s3_bucket" "s3_utils_bucket" {
  bucket = "realestate-script-1799"
}

# Upload Glue script (ETL.py) to the root of the S3 bucket
resource "aws_s3_object" "add_script" {
  depends_on = [aws_s3_bucket.s3_utils_bucket]
  bucket     = aws_s3_bucket.s3_utils_bucket.bucket
  key        = "etl.py"  # This uploads the file directly to the root of the bucket
  source     = "./scripts/etl.py"  # Update this with the path to your local file
  etag       = filemd5("./scripts/etl.py")
}



resource "aws_glue_job" "s3_to_redshift_glue_job" {
  name         = "job8"
  role_arn     = aws_iam_role.iam_for_glue.arn
  glue_version = "4.0"
  worker_type  = "G.1X"
  number_of_workers = 2
  timeout           = 30
  connections = [
    var.glue_jdbc_conn_name,
  ]
  command {
    script_location = "s3://realestate-script-1799/etl.py"
  }
  default_arguments = {
    "--class"                   = "GlueApp"
    "--enable-job-insights"     = "true"
    "--enable-auto-scaling"     = "false"
    "--enable-glue-datacatalog" = "true"
    "--job-language"            = "python"
    "--job-bookmark-option"     = "job-bookmark-disable"
  }

}
#create a trigger for glue crawlers
resource "aws_glue_trigger" "glue_trigger" {
  name     = "glue-trigger8"
  schedule = "cron(0/5 * * * ? *)"  # Modify cron schedule as needed
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.s3_to_redshift_glue_job.name
  }
}