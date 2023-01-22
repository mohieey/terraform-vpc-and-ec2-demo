# 2- Create custom subnet
resource "aws_subnet" "my-vpc-subnet" {
  vpc_id     = var.vpc_id
  cidr_block = var.vpc_subnet_cidr_block
  availability_zone = var.az
  tags = { 
    Name: "${var.env_prefix}-vpc-sub"
  }
}



# 3- Create Route Table & IGW
resource "aws_route_table" "my-route-table" {
  vpc_id     = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-internet-gateway.id
  }

  tags =  {
    Name: "${var.env_prefix}-rt"
  }

}

resource "aws_internet_gateway" "my-internet-gateway" {
  vpc_id     = var.vpc_id

  tags  = {
    Name: "${var.env_prefix}-igw"
  }
}

resource "aws_route_table_association" "my-route-table-association" {
    subnet_id = aws_subnet.my-vpc-subnet.id
    route_table_id = aws_route_table.my-route-table.id
}



