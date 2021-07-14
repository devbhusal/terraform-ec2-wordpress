provider "aws" {
  
  region  = "ap-southeast-2"
  shared_credentials_file = "C:/Users/61424/.aws"
}

resource "aws_security_group" "allow_rule" {
 
  
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
    Name = "allow ssh,http,https"
  }
}


resource "aws_instance" "wordpress" {
  ami           = "ami-0c9fe0dec6325a30c"
  instance_type = "t2.micro"
  security_groups=["${aws_security_group.allow_rule.name}"]
  user_data=file("./userdata.sh")
  key_name ="mykeypair"
  tags = {
    Name = "Wordpress.web"
  }
}

resource "aws_eip" "eip" {
  instance = aws_instance.wordpress.id
  
}

output "IP" {
    value = aws_eip.eip.public_ip
}




