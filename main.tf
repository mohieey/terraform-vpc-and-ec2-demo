# 1- Create custom VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { 
    Name: "${var.env_prefix}-vpc",
  }
}


module "my-subnet" {
  source = "./modules/subnet"
  vpc_subnet_cidr_block = var.vpc_subnet_cidr_block
  az = var.az
  env_prefix = var.env_prefix
  vpc_id = aws_vpc.my-vpc.id
}

module "my-server" {
  source = "./modules/server"
  instance_type = var.instance_type
  public_key_location = var.public_key_location
  env_prefix = var.env_prefix
  vpc_id = aws_vpc.my-vpc.id
  my_ip = var.my_ip
  subnet_id = module.my-subnet.subnet.id
}

# 5- Deploy nginx docker container
# 6- Create SG