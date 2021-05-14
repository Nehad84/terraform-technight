#Configure the AWS Provider
provider "aws" {
  region = "eu-west-3"
}

#variable section
variable "t2_availability_zone1" {}
variable "t2_availability_zone2" {}
variable "t2_availability_zone3" {}
variable "t2_vpc_cidr_block" {}
variable "t2_pubsubnet1_cidr" {}
variable "t2_pubsubnet2_cidr" {}
variable "t2_pubsubnet3_cidr" {}
variable "t2_prvsubnet1_cidr" {}
variable "t2_prvsubnet2_cidr" {}
variable "t2_prvsubnet3_cidr" {}
variable "t2_prefix" {}

#-----------------------------------------------------------------
#vpc section

#Create a VPC
resource "aws_vpc" "demo2_vpc" {
    cidr_block = var.t2_vpc_cidr_block[0].cidr
    #for eks
    enable_dns_support = true
    enable_dns_hostnames =true
    tags={
        Name: "${var.t2_prefix}-${var.t2_vpc_cidr_block[0].name}"
    }
}
#-----------------------------------------------------------------
#subnet section

#Create a public subnet1
resource "aws_subnet" "demo2_pub_subnet_1" {
    vpc_id= aws_vpc.demo2_vpc.id
    cidr_block = var.t2_pubsubnet1_cidr[0].cidr
    availability_zone= var.t2_availability_zone1
    #for eks
    map_public_ip_on_launch = true
    tags={
        Name: "${var.t2_prefix}-${var.t2_pubsubnet1_cidr[0].name}"
        #for eks
        "kubernetes.io/cluster/eks" = "shared"
        "kubernetes.io/role/elb" = 1
    }
}

#Create a public subnet2
resource "aws_subnet" "demo2_pub_subnet_2" {
    vpc_id= aws_vpc.demo2_vpc.id
    cidr_block = var.t2_pubsubnet2_cidr[0].cidr
    availability_zone= var.t2_availability_zone2
    #for eks
    map_public_ip_on_launch = true
    tags={
        Name: "${var.t2_prefix}-${var.t2_pubsubnet2_cidr[0].name}"
        #for eks
        "kubernetes.io/cluster/eks" = "shared"
        "kubernetes.io/role/elb" = 1
    }
}

#Create a public subnet3
resource "aws_subnet" "demo2_pub_subnet_3" {
    vpc_id= aws_vpc.demo2_vpc.id
    cidr_block = var.t2_pubsubnet3_cidr[0].cidr
    availability_zone= var.t2_availability_zone3
    #for eks
    map_public_ip_on_launch = true
    tags={
        Name: "${var.t2_prefix}-${var.t2_pubsubnet3_cidr[0].name}"
        #for eks
        "kubernetes.io/cluster/eks" = "shared"
        "kubernetes.io/role/elb" = 1
    }
}

#Create a private subnet1
resource "aws_subnet" "demo2_prvt_subnet_1" {
    vpc_id= aws_vpc.demo2_vpc.id
    cidr_block = var.t2_prvsubnet1_cidr[0].cidr
    availability_zone= var.t2_availability_zone1
    tags={
        Name: "${var.t2_prefix}-${var.t2_prvsubnet1_cidr[0].name}"
        #for eks
        "kubernetes.io/cluster/eks" = "shared"
        "kubernetes.io/role/internal-elb" = 1
    }
}

#Create a private subnet2
resource "aws_subnet" "demo2_prvt_subnet_2" {
    vpc_id= aws_vpc.demo2_vpc.id
    cidr_block = var.t2_prvsubnet2_cidr[0].cidr
    availability_zone= var.t2_availability_zone2 
    tags={
        Name: "${var.t2_prefix}-${var.t2_prvsubnet2_cidr[0].name}"
        #for eks
        "kubernetes.io/cluster/eks" = "shared"
        "kubernetes.io/role/internal-elb" = 1
    }
}
#Create a private subnet3
resource "aws_subnet" "demo2_prvt_subnet_3" {
    vpc_id= aws_vpc.demo2_vpc.id
    cidr_block = var.t2_prvsubnet3_cidr[0].cidr
    availability_zone= var.t2_availability_zone3
    tags={
        Name: "${var.t2_prefix}-${var.t2_prvsubnet3_cidr[0].name}"
        #for eks
        "kubernetes.io/cluster/eks" = "shared"
        "kubernetes.io/role/internal-elb" = 1
    }
}
#-----------------------------------------------------------------
#internet gateway and NAT section

#Create an internet gateway
resource "aws_internet_gateway" "demo2_internet_gateway" {
    vpc_id= aws_vpc.demo2_vpc.id
    tags={
        Name: "${var.t2_prefix}-igw"
    }
}

#Create a public ip for nat
resource "aws_eip" "demo2_nat_eip" {
  depends_on= [aws_internet_gateway.demo2_internet_gateway]
}

#Create a nat
resource "aws_nat_gateway" "demo2_nat" {
  allocation_id = aws_eip.demo2_nat_eip.id
  subnet_id     = aws_subnet.demo2_pub_subnet_1.id
  tags={
        Name: "${var.t2_prefix}-nat"
    }
}
#-----------------------------------------------------------------
#route tables section and assocciation

#Create a public route table
resource "aws_route_table" "demo2_pub_route_table" {
    vpc_id= aws_vpc.demo2_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id= aws_internet_gateway.demo2_internet_gateway.id
    }
    tags={
        Name: "${var.t2_prefix}-pub-rtb"
    }
}

# Associate subnet1 with public route table
resource "aws_route_table_association" "demo2_pub_rtb_subnet1" {
    subnet_id      = aws_subnet.demo2_pub_subnet_1.id
    route_table_id = aws_route_table.demo2_pub_route_table.id
}

# Associate subnet2 with public route table
resource "aws_route_table_association" "demo2_pub_rtb_subnet2" {
    subnet_id      = aws_subnet.demo2_pub_subnet_2.id
    route_table_id = aws_route_table.demo2_pub_route_table.id
}

# Associate subnet3 with public route table
resource "aws_route_table_association" "demo2_pub_rtb_subnet3" {
    subnet_id      = aws_subnet.demo2_pub_subnet_3.id
    route_table_id = aws_route_table.demo2_pub_route_table.id
}

#Create a private route table
resource "aws_route_table" "demo2_prvt_route_table" {
    vpc_id= aws_vpc.demo2_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id= aws_nat_gateway.demo2_nat.id
    }
    tags={
        Name: "${var.t2_prefix}-prvt-rtb"
    }
}

# Associate subnet4 with private route table
resource "aws_route_table_association" "demo2_prvt_rtb_subnet1" {
    subnet_id      = aws_subnet.demo2_prvt_subnet_1.id
    route_table_id = aws_route_table.demo2_prvt_route_table.id
}

# Associate subnet5 with private route table
resource "aws_route_table_association" "demo2_prvt_rtb_subnet2" {
    subnet_id      = aws_subnet.demo2_prvt_subnet_2.id
    route_table_id = aws_route_table.demo2_prvt_route_table.id
}

# Associate subnet6 with private route table
resource "aws_route_table_association" "demo2_prvt_rtb_subnet3" {
    subnet_id      = aws_subnet.demo2_prvt_subnet_3.id
    route_table_id = aws_route_table.demo2_prvt_route_table.id
}
#-----------------------------------------------------------------
#eks
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Create Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
      endpoint_private_access = false
      endpoint_public_access = true
      subnet_ids = [
          aws_subnet.demo2_pub_subnet_1.id, 
          aws_subnet.demo2_pub_subnet_2.id,
          aws_subnet.demo2_pub_subnet_3.id, 
          aws_subnet.demo2_prvt_subnet_1.id,
          aws_subnet.demo2_prvt_subnet_2.id, 
          aws_subnet.demo2_prvt_subnet_3.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
  ]
}

resource "aws_iam_role" "nodes_general" {
  
  name = "eks-node-group-general"

  # The policy that grants an entity permission to assume the role.
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }, 
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy_general" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.nodes_general.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy_general" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.nodes_general.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.nodes_general.name
}

resource "aws_eks_node_group" "nodes_general" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  node_group_name = "nodes-general"
  node_role_arn = aws_iam_role.nodes_general.arn

  subnet_ids = [
    aws_subnet.demo2_prvt_subnet_1.id,
    aws_subnet.demo2_prvt_subnet_2.id, 
    aws_subnet.demo2_prvt_subnet_3.id
  ]

  scaling_config {
    desired_size = 3
    max_size = 3
    min_size = 3
  }
  ami_type = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  disk_size = 20
  force_update_version = false
  instance_types = ["t3.small"]
  labels = {
    role = "nodes-general"
  }
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy_general,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy_general,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]
}