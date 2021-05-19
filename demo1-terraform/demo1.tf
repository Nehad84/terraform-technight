# Configure the AWS Provider
provider "aws" {
    profile= "nehadcli"
    region = "eu-west-3"
}


#variable section
variable "t1_availability_zone1" {
    
}
variable "t1_availability_zone2" {}
variable "t1_vpc_cidr_block" {}
variable "t1_pubsubnet1_cidr" {}
variable "t1_pubsubnet2_cidr" {}
variable "t1_prvsubnet1_cidr" {}
variable "t1_prvsubnet2_cidr" {}
variable "t1_prefix" {}
variable "t1_instance_type" {}
#-----------------------------------------------------------------
#vpc section

#Create a VPC
resource "aws_vpc" "demo1_vpc" {
    cidr_block = var.t1_vpc_cidr_block[0].cidr
    tags={
        Name: "${var.t1_prefix}-${var.t1_vpc_cidr_block[0].name}"
    }
}
#-----------------------------------------------------------------
#subnet section

#Create a public subnet1
resource "aws_subnet" "demo1_pub_subnet_1" {
    vpc_id= aws_vpc.demo1_vpc.id
    cidr_block = var.t1_pubsubnet1_cidr[0].cidr
    availability_zone= var.t1_availability_zone1
    tags={
        Name: "${var.t1_prefix}-${var.t1_pubsubnet1_cidr[0].name}"
    }
}

#Create a public subnet2
resource "aws_subnet" "demo1_pub_subnet_2" {
    vpc_id= aws_vpc.demo1_vpc.id
    cidr_block = var.t1_pubsubnet2_cidr[0].cidr
    availability_zone= var.t1_availability_zone2
    tags={
        Name: "${var.t1_prefix}-${var.t1_pubsubnet2_cidr[0].name}"
    }
}

#Create a private subnet1
resource "aws_subnet" "demo1_prvt_subnet_1" {
    vpc_id= aws_vpc.demo1_vpc.id
    cidr_block = var.t1_prvsubnet1_cidr[0].cidr
    availability_zone= var.t1_availability_zone1
    tags={
        Name: "${var.t1_prefix}-${var.t1_prvsubnet1_cidr[0].name}"
    }
}

#Create a private subnet2
resource "aws_subnet" "demo1_prvt_subnet_2" {
    vpc_id= aws_vpc.demo1_vpc.id
    cidr_block = var.t1_prvsubnet2_cidr[0].cidr
    availability_zone= var.t1_availability_zone2 
    tags={
        Name: "${var.t1_prefix}-${var.t1_prvsubnet2_cidr[0].name}"
    }
}
#-----------------------------------------------------------------
#internet gateway and NAT section

#Create an internet gateway
resource "aws_internet_gateway" "demo1_internet_gateway" {
    vpc_id= aws_vpc.demo1_vpc.id
    tags={
        Name: "${var.t1_prefix}-igw"
    }
}

#Create a public ip for nat
resource "aws_eip" "demo1_nat_eip" {
  depends_on= [aws_internet_gateway.demo1_internet_gateway]
}

#Create a nat
resource "aws_nat_gateway" "demo1_nat" {
  allocation_id = aws_eip.demo1_nat_eip.id
  subnet_id     = aws_subnet.demo1_pub_subnet_1.id
  tags={
        Name: "${var.t1_prefix}-nat"
    }
}
#-----------------------------------------------------------------
#route tables section and assocciation

#Create a public route table
resource "aws_route_table" "demo1_pub_route_table" {
    vpc_id= aws_vpc.demo1_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id= aws_internet_gateway.demo1_internet_gateway.id
    }
    tags={
        Name: "${var.t1_prefix}-pub-rtb"
    }
}

# Associate subnet1 with public route table
resource "aws_route_table_association" "demo1_pub_rtb_subnet1" {
    subnet_id      = aws_subnet.demo1_pub_subnet_1.id
    route_table_id = aws_route_table.demo1_pub_route_table.id
}

# Associate subnet2 with public route table
resource "aws_route_table_association" "demo1_pub_rtb_subnet2" {
    subnet_id      = aws_subnet.demo1_pub_subnet_2.id
    route_table_id = aws_route_table.demo1_pub_route_table.id
}

#Create a private route table
resource "aws_route_table" "demo1_prvt_route_table" {
    vpc_id= aws_vpc.demo1_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id= aws_nat_gateway.demo1_nat.id
    }
    tags={
        Name: "${var.t1_prefix}-prvt-rtb"
    }
}

# Associate subnet3 with private route table
resource "aws_route_table_association" "demo1_prvt_rtb_subnet1" {
    subnet_id      = aws_subnet.demo1_prvt_subnet_1.id
    route_table_id = aws_route_table.demo1_prvt_route_table.id
}

# Associate subnet4 with private route table
resource "aws_route_table_association" "demo1_prvt_rtb_subnet2" {
    subnet_id      = aws_subnet.demo1_prvt_subnet_2.id
    route_table_id = aws_route_table.demo1_prvt_route_table.id
}
#-----------------------------------------------------------------
#security group

#Create public security group
resource "aws_security_group" "demo1_pub_sg" {
    name= "demo1_pub_sg"
    vpc_id= aws_vpc.demo1_vpc.id

    ingress {
        from_port= 80
        to_port= 80
        protocol= "tcp"
        cidr_blocks= ["0.0.0.0/0"]
    }

    ingress {
        from_port= 22
        to_port= 22
        protocol= "tcp"
        cidr_blocks= ["0.0.0.0/0"]
    }

    egress {
        from_port= 0
        to_port= 0
        protocol= "-1"
        cidr_blocks= ["0.0.0.0/0"]
    }
    tags = {
        Name = "${var.t1_prefix}-public_sg"
    }
}

#Create private security group
resource "aws_security_group" "demo1_prvt_sg" {
    name= "demo1_prvt_sg"
    vpc_id= aws_vpc.demo1_vpc.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = [var.t1_pubsubnet1_cidr[0].cidr,var.t1_pubsubnet2_cidr[0].cidr]
    }


    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "${var.t1_prefix}-private_sg"
    }
}
#-----------------------------------------------------------------
#ec2

#query ami
data "aws_ami" "latest_centos_image" {
    most_recent= true
    owners=["285398391915"]
    filter {
        name   = "name"
        values = ["ami-centos-7-1*"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
    filter {
    name   = "root-device-type"
    values = ["ebs"]
    }
}

#check the output
output "ami_returned" {
    value = data.aws_ami.latest_centos_image
}



#Create a centos instance
resource "aws_instance" "demo1_centos1_private" {
    ami= data.aws_ami.latest_centos_image.id
    instance_type= var.t1_instance_type
    subnet_id= aws_subnet.demo1_prvt_subnet_1.id
    vpc_security_group_ids= [aws_security_group.demo1_prvt_sg.id]
    availability_zone= var.t1_availability_zone1
    key_name= "eu-west-demo"
    #associate_public_ip_address= true
    user_data = <<-EOF
                #!/bin/bash
                #/usr/share/nginx/html
                sudo yum update -y
                sudo yum install nginx -y 
                sudo rm /usr/share/nginx/html/index.html
                cat >>/usr/share/nginx/html/index.html<<aaa
                    <html>
                        <body>
                            This is server 1 private 
                        </body>
                    </html>
                aaa
                sudo systemctl enable nginx --now
            EOF
    tags = {
        Name = "${var.t1_prefix}-centos1-private"
    }
}


#Create a centos instance
resource "aws_instance" "demo1_centos2_private" {
    ami= data.aws_ami.latest_centos_image.id
    instance_type= var.t1_instance_type
    subnet_id= aws_subnet.demo1_prvt_subnet_2.id
    vpc_security_group_ids= [aws_security_group.demo1_prvt_sg.id]
    availability_zone= var.t1_availability_zone2
    #associate_public_ip_address= true
    key_name= "eu-west-demo"
    user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install nginx -y 
                sudo rm /usr/share/nginx/html/index.html
                cat >>/usr/share/nginx/html/index.html<<aaa
                    <html>
                        <body>
                            This is server 2 private 
                        </body>
                    </html>
                aaa
                sudo systemctl enable nginx --now
            EOF
    tags = {
        Name = "${var.t1_prefix}-centos2-private"
    }
}


#Create a centos instance
resource "aws_instance" "demo1_centos1_public" {
    ami= data.aws_ami.latest_centos_image.id
    instance_type= var.t1_instance_type
    subnet_id= aws_subnet.demo1_pub_subnet_1.id
    vpc_security_group_ids= [aws_security_group.demo1_pub_sg.id]
    availability_zone= var.t1_availability_zone1
    associate_public_ip_address= true
    key_name= "eu-west-demo"
    user_data = <<-EOF
                    #!/bin/bash
                    sudo yum update -y
                    sudo yum install nginx -y 
                    
                    sudo rm /etc/nginx/conf.d/default.conf
                    #/etc/nginx/ngix.conf
                    sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf_
                    sudo cat >>/etc/nginx/nginx.conf<<aaa
                        


                        events {worker_connections  1024;}
                        http {
                            log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                            '$status $body_bytes_sent "$http_referer" '
                            '"$http_user_agent" "$http_x_forwarded_for"';

                            access_log  /var/log/nginx/access.log  main;

                            sendfile            on;
                            tcp_nopush          on;
                            tcp_nodelay         on;
                            keepalive_timeout   65;
                            types_hash_max_size 2048;

                            include             /etc/nginx/mime.types;
                            default_type        application/octet-stream;

                            include /etc/nginx/conf.d/*.conf;
                            server {
                                listen 80;
                                location / {
                                    proxy_pass http://${aws_instance.demo1_centos1_private.private_ip};
                                    proxy_redirect off;
                                    proxy_set_header Host \$host;
                                    proxy_set_header X-Real-IP \$remote_addr;
                                    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                                    proxy_max_temp_file_size 0;
                                    #proxy_temp_file_write_size 4k;
                                    client_max_body_size 10m;
                                    client_body_buffer_size 128k;
                                    proxy_connect_timeout 90;
                                    proxy_send_timeout 90;
                                    proxy_read_timeout 90;
                                    proxy_buffer_size 4k;
                                    proxy_buffers 4 32k;
                                    proxy_busy_buffers_size 64k;
                                proxy_temp_file_write_size 64k;
                                }

                            }
                        }
                    aaa
                    sudo systemctl enable nginx --now
                EOF
    tags = {
        Name = "${var.t1_prefix}-centos1-public"
    }
    depends_on = [
    aws_instance.demo1_centos1_private
  ]
}

#Create a centos instance
resource "aws_instance" "demo1_centos2_public" {
    ami= data.aws_ami.latest_centos_image.id
    instance_type= var.t1_instance_type
    subnet_id= aws_subnet.demo1_pub_subnet_2.id
    vpc_security_group_ids= [aws_security_group.demo1_pub_sg.id]
    availability_zone= var.t1_availability_zone2
    associate_public_ip_address= true
    key_name= "eu-west-demo"
    user_data = <<-EOF
                    #!/bin/bash
                    sudo yum update -y
                    sudo yum install nginx -y 
                    
                    sudo rm /etc/nginx/conf.d/default.conf
                    #/etc/nginx/ngix.conf
                    sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf_
                    sudo cat >>/etc/nginx/nginx.conf<<aaa
                        


                        events {worker_connections  1024;}
                        http {
                            log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                            '$status $body_bytes_sent "$http_referer" '
                            '"$http_user_agent" "$http_x_forwarded_for"';

                            access_log  /var/log/nginx/access.log  main;

                            sendfile            on;
                            tcp_nopush          on;
                            tcp_nodelay         on;
                            keepalive_timeout   65;
                            types_hash_max_size 2048;

                            include             /etc/nginx/mime.types;
                            default_type        application/octet-stream;

                            include /etc/nginx/conf.d/*.conf;
                            server {
                                listen 80;
                                location / {
                                    proxy_pass http://${aws_instance.demo1_centos2_private.private_ip};
                                    proxy_redirect off;
                                    proxy_set_header Host \$host;
                                    proxy_set_header X-Real-IP \$remote_addr;
                                    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                                    proxy_max_temp_file_size 0;
                                    #proxy_temp_file_write_size 4k;
                                    client_max_body_size 10m;
                                    client_body_buffer_size 128k;
                                    proxy_connect_timeout 90;
                                    proxy_send_timeout 90;
                                    proxy_read_timeout 90;
                                    proxy_buffer_size 4k;
                                    proxy_buffers 4 32k;
                                    proxy_busy_buffers_size 64k;
                                proxy_temp_file_write_size 64k;
                                }

                            }
                        }
                    aaa
                    sudo systemctl enable nginx --now
                EOF
    tags = {
        Name = "${var.t1_prefix}-centos2-public"
    }
    depends_on = [
    aws_instance.demo1_centos2_private
  ]
}