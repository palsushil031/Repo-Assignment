provider "aws" {
  region = "us-east-1"
}

variable "cidr" {
  default = "10.0.0.0/16"
}

# ssh-keygen -t rsa -> to generate the key
resource "aws_key_pair" "AssignmentQues7" {
  key_name = "Assignment_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDlxWOhSIT/dbEGXyz0TPO8632d2E2RLIRaJW7dtJ+9+TQtFT+XkZdKyrcQiffFxaQ2kaM4K4McEffb2wkVeYeotjpSJ6YdM+01VE8yrlXbEeZ5Ixks07peFdHI3SiHf1CWWcOBFX1VmtZtIFPZ7IEB9BmkjOqJw3fiH4M/tn33zIKuBBF2Q15Xu+Jhc1xDxZDcv06t5QBcIgydHDvSKSb5lKiPJfDa+PlnDgsdEfcxZBAyzDWT2wO2oaAkBbkUN+l6qlPxnUw2TohLYTLt2OpQnCBQR8FGerSQpE01MASgkw6jxYQVw9M+S96ufV9BkTJlO1YXXw52SDcLa1Ir/bV5cILPIyufCGcqze52ngoE7Ed5YEfbyI87V6Z6JXl7X/haxbZZxOch6XPF5tkpVPr7YR35s7iThRRubVben/cI3S/8JU0DWYhfe2Jp5kDMtQFdPVohdLlEG+nG8I2QMdmvZ4mJYjnN0E0kBN4oKXPF9bWxkTPe6oXCwTi3dZW+EP0= palsu@Sushil"
}

resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

# create subnet
resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1"
  map_public_ip_on_launch = true
}

# create Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

# routetable and attach the IGW to routetable/destination
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block="0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# assocaiate the route table with subnet
resource "aws_route_table_association" "rta1" {
  subnet_id = aws_subnet.subnet1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "webSg" {
  name = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "http from VPC"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-sg"
  }
}

resource "aws_instance" "AssignmentServer" {
  ami = "ami-0866a3c8686eaeeba"
  instance_type = "t2.micro"
  key_name = aws_key_pair.AssignmentQues7.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id = aws_subnet.subnet1.id

# remote-exec provisioner - install NGINX
  provisioner "remote-exec" {
    connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "~/.ssh/sushil"
    host = self.public_ip
  }
  
  inline = [
      "sudo apt update",
      "sudo apt install nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]
  }
  tags = {
    Name = "nginx-server"
  }
}

