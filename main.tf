variable region {
  type        = string
}
variable access_key {
  type        = string
}
variable secret_key {
  type        = string
}
provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# 1- Create custom VPC
variable vpc_cidr_block {
  type        = string
}
variable vpc_subnet_cidr_block {
  type        = string
}
variable az {
  type        = string
}
variable env_prefix {
  type        = string
}
variable my_ip {
  type        = string
}
variable instance_type {
  type        = string
}
variable public_key_location {
  type        = string
}
variable private_key_location {
  type        = string
}


resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { 
    Name: "${var.env_prefix}-vpc",
  }
}






# 2- Create custom subnet
resource "aws_subnet" "my-vpc-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = var.vpc_subnet_cidr_block
  availability_zone = var.az
  tags = { 
    Name: "${var.env_prefix}-vpc-sub"
  }
}



# 3- Create Route Table & IGW
resource "aws_route_table" "my-route-table" {
  vpc_id     = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-internet-gateway.id
  }

  tags =  {
    Name: "${var.env_prefix}-rt"
  }

}

resource "aws_internet_gateway" "my-internet-gateway" {
  vpc_id     = aws_vpc.my-vpc.id

  tags  = {
    Name: "${var.env_prefix}-igw"
  }
}

resource "aws_route_table_association" "my-route-table-association" {
    subnet_id = aws_subnet.my-vpc-subnet.id
    route_table_id = aws_route_table.my-route-table.id
}

resource "aws_security_group" "my-sg" {
    name = "my-sg"
    vpc_id = aws_vpc.my-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0 #any port
        to_port = 0 #any port
        protocol = "-1" #any protocol
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags  = {
        Name: "${var.env_prefix}-sg"
    }
}


# 4- Provision EC2 inst.
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-kernel-5*-x86_64-gp2"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name = "${var.env_prefix}-key"
  public_key = "${file(var.public_key_location)}" #generated using ssh-keygen
}

resource "aws_instance" "my-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.my-vpc-subnet.id
  vpc_security_group_ids = [aws_security_group.my-sg.id]
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  # user_data = file("user_data.sh")
  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_location)
  }

  #to copy a file to the remote machine 
  provisioner "file" {
    source = "user_data.sh"
    destination = "/home/ec2-user/user_data.sh"
  }

  # provisioner "file" {
  #   source = "user_data.sh"
  #   destination = "/home/ec2-user/user_data.sh"

  #   #having a separate connection
  #   connection {
  #     type = "ssh"
  #     host = someotherserver.public_ip
  #     user = "ec2-user"
  #     private_key = file(var.private_key_location)
  #   }
  # }


  provisioner "remote-exec" {
    # inline = [
    #   "sudo yum update -y && sudo yum install -y docker",
    #   "sudo systemctl start docker",
    #   "sudo usermod -aG docker ec2-user", 
    #   "docker run -p 8080:80 nginx"
    # ]

    # or
    # script = file("./user_data.sh")
    
    inline = [
        "chmod +x /home/ec2-user/user_data.sh",
        "~/user_data.sh",
    ]
  }

  # it's better to use local provider not provisioner
  # provisioner "local-exec" {
  #   command = "echo ${self.public_ip} > ip.txt"
  # }

  tags = {
    Name:  "${var.env_prefix}-server"
  }
}

output "my-server-ip" {
  value       = aws_instance.my-server.public_ip
}


# 5- Deploy nginx docker container
# 6- Create SG