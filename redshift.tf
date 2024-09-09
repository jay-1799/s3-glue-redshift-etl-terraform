resource "aws_vpc" "redshift-serverless-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "redshift_subnet_az1" {
  vpc_id = aws_vpc.redshift-serverless-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "redshift_subnet_az2" {
  vpc_id = aws_vpc.redshift-serverless-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "redshift_subnet_az3" {
  vpc_id = aws_vpc.redshift-serverless-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "redshift_route_table" {
  vpc_id = aws_vpc.redshift-serverless-vpc.id
}

resource "aws_route_table_association" "redshift_route_table_association" {
  count          = 3
  subnet_id      = element([aws_subnet.redshift_subnet_az1.id, aws_subnet.redshift_subnet_az2.id, aws_subnet.redshift_subnet_az3.id], count.index)
  route_table_id = aws_route_table.redshift_route_table.id
}

resource "aws_security_group" "redshift-serverless-security-group" {
  depends_on = [aws_vpc.redshift-serverless-vpc]

  name        = "sg8"
  description = "redshift-serverless-security-group"

  vpc_id = aws_vpc.redshift-serverless-vpc.id

  ingress {
    description = "all traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # This opens all outbound traffic
  }

  tags = {
    Name = "redshift-serverless-security-group"
  }
}

resource "aws_vpc_endpoint" "s3_redshift" {
  vpc_id            = aws_vpc.redshift-serverless-vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

#   route_table_ids = [aws_vpc.redshift-serverless-vpc.default_route_table_id]
route_table_ids = [aws_route_table.redshift_route_table.id]
}

resource "aws_redshiftserverless_namespace" "serverless" {
  namespace_name = "nsw-property-namespace"
  db_name = "nsw_properties"
  admin_username = var.redshift_serverless_admin_username
  admin_user_password = var.redshift_serverless_admin_password
  iam_roles = [aws_iam_role.redshift-serverless-role.arn]
}

resource "aws_redshiftserverless_workgroup" "serverless" {
  depends_on = [aws_redshiftserverless_namespace.serverless]
  namespace_name = aws_redshiftserverless_namespace.serverless.namespace_name
  workgroup_name = "nsw-workgroup"
  base_capacity = 32
  security_group_ids = [aws_security_group.redshift-serverless-security-group.id]
  subnet_ids = [
    aws_subnet.redshift_subnet_az1.id,
    aws_subnet.redshift_subnet_az2.id,
    aws_subnet.redshift_subnet_az3.id,
  ]
  publicly_accessible = false
}


#create jdbc connection
resource "aws_glue_connection" "glue_jdbc_conn" {
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:redshift://${aws_redshiftserverless_workgroup.serverless.endpoint[0].address}:${aws_redshiftserverless_workgroup.serverless.port}/dev"
    PASSWORD            = var.redshift_serverless_admin_password
    USERNAME            = var.redshift_serverless_admin_username
  }
  name = var.glue_jdbc_conn_name
  physical_connection_requirements {
    availability_zone = aws_subnet.redshift_subnet_az1.availability_zone
    security_group_id_list = [
      aws_security_group.redshift-serverless-security-group.id,
    ]
    subnet_id = aws_subnet.redshift_subnet_az1.id
  }
}