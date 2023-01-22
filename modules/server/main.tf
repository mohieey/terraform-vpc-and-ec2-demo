resource "aws_security_group" "my-sg" {
    name = "my-sg"
    vpc_id = var.vpc_id

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

  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.my-sg.id]
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  user_data = file("user_data.sh")

  tags = {
    Name:  "${var.env_prefix}-server"
  }
}