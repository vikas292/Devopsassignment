terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
/*
#Configure the AWS provider 
provider "aws" {
    region = "ap-south-1"
    access_key = "AKIAJIIDYHQXB5AV24WQ"
    secret_key = "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"
}
*/
#Create VPC
resource "aws_vpc" "Prod_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Prod"
  }
}
#Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.Prod_vpc.id


}
#Create Route table
resource "aws_route_table" "Prod_routetable" {
  vpc_id = aws_vpc.Prod_vpc.id  # refernce vpc_id 

  route {
    cidr_block = "0.0.0.0/0"                # Send All ipv4 traffic whereever this route points(default route)
    gateway_id = aws_internet_gateway.igw.id  # Refernce Gateway id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Prod_RT"
  }
}
# Create Subnet
resource "aws_subnet" "Subnet1" {
  vpc_id     = aws_vpc.Prod_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Prod_Subnet"
  }
}
#Associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.Subnet1.id
  route_table_id = aws_route_table.Prod_routetable.id

}
#Create Security group to allow port 22,443,80

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.Prod_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_Traffic"
  }
}
 #Create Network INterface (Created private IP for th Host)
 resource "aws_network_interface" "NTF" {
  subnet_id       = aws_subnet.Subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

#Also want to assign a public IP so everybody on the internet can access it (Created Elastic IP) 
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.NTF.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_instance" "Prod_EC2" {
  ami = "ami-0cda377a1b884a1bc"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.NTF.id

  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemt1 start apahe2
              sudo bash -c 'echo Hi Pankaj, I have completed my Devops Assignment and It was really a great experience.I really wish to join your team to work on these exciting projects and devlop my career in Devops> /var/www/html/index.html'
              EOF
            

  tags = {
    Name = "Web server"
  }

}