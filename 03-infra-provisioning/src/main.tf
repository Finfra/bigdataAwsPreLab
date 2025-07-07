# main.tf
provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "prelab_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "prelab-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.prelab_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "prelab-public-subnet"
  }
}

resource "aws_internet_gateway" "prelab_igw" {
  vpc_id = aws_vpc.prelab_vpc.id
  tags = {
    Name = "prelab-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.prelab_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prelab_igw.id
  }
  tags = {
    Name = "prelab-public-rt"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.prelab_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For SSH from anywhere (for lab purposes)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080 # Spark Master UI
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8088 # YARN ResourceManager UI
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9870 # Hadoop NameNode UI
    to_port     = 9870
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090 # Prometheus UI
    to_port     = 9090
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
    Name = "prelab-sg"
  }
}

data "aws_ami" "oracle_linux" {
  most_recent = true
  owners      = ["oracle"]

  filter {
    name   = "name"
    values = ["Oracle-Linux-9-*-x86_64-*"]
  }
}

resource "aws_key_pair" "prelab_key" {
  key_name   = "prelab-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "console_server" {
  ami           = data.aws_ami.oracle_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = aws_key_pair.prelab_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  tags = {
    Name = "console-server"
  }
}

resource "aws_eip" "console_eip" {
  instance = aws_instance.console_server.id
  vpc      = true
}

resource "aws_instance" "data_nodes" {
  count         = 3
  ami           = data.aws_ami.oracle_linux.id
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public_subnet.id # For simplicity, placing in public subnet for now
  key_name      = aws_key_pair.prelab_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  tags = {
    Name = "s${count.index + 1}"
  }
}
