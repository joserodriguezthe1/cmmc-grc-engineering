# =============================================================================
# Networking module — System & Communications Protection (SC)
# Implements: SC.L2-3.13.1 (boundary), 3.13.5 (public subnet separation),
#             3.13.6 (deny by default), SI.L2-3.14.6 (flow logs)
# Free-Tier: VPC/subnets/SG/NACL are free. NO NAT Gateway (it costs ~$32/mo).
#            S3 access uses a free Gateway VPC endpoint.
# =============================================================================

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.name_prefix}-vpc" }
}

# SC.L2-3.13.5 : public subnet for internet-facing components only
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 0)
  availability_zone = "${var.region}a"
  tags              = { Name = "${var.name_prefix}-public", Tier = "public" }
}

# Private subnet holds the CUI-processing components
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = "${var.region}a"
  tags              = { Name = "${var.name_prefix}-private", Tier = "private" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private route table (no NAT — egress to AWS services via VPC endpoints)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name_prefix}-private-rt" }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Free Gateway endpoint so private subnet reaches S3 without a NAT gateway
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.this.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.private.id]
  tags            = { Name = "${var.name_prefix}-s3-endpoint" }
}

# SC.L2-3.13.6 : deny-by-default security group (no ingress; egress to TLS only)
resource "aws_security_group" "default_deny" {
  name        = "${var.name_prefix}-deny-default"
  description = "Deny-by-default. Add explicit ingress per workload (SC.L2-3.13.6)."
  vpc_id      = aws_vpc.this.id

  egress {
    description = "Allow outbound HTTPS only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-deny-default" }
}

# SI.L2-3.14.6 : VPC flow logs to CloudWatch (role/log group from logging module)
resource "aws_flow_log" "this" {
  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
  iam_role_arn    = var.flow_log_role_arn
  log_destination = var.log_destination_arn
}
