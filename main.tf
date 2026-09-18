resource "aws_vpc" "togglemaster" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "togglemaster-vpc"
  }
}
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.togglemaster.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-a"
  }
}
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.togglemaster.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-b"
  }
}
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.togglemaster.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-a"
  }
}
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.togglemaster.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.togglemaster.id
  tags = {
    Name = "togglemaster-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.togglemaster.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "eks" {
  name        = "togglemaster-eks-sg"
  description = "Security Group EKS"
  vpc_id      = aws_vpc.togglemaster.id
  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "togglemaster-eks-sg"
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "togglemaster-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_cluster" "togglemaster" {
  name     = "togglemaster-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id,
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]
    security_group_ids = [
      aws_security_group.eks.id
    ]
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
resource "aws_iam_role" "eks_node_role" {
  name = "togglemaster-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.togglemaster.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }
  instance_types = ["t3.small"]
  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly
  ]
}
resource "aws_iam_role_policy_attachment" "worker_node_minimal" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
}
resource "aws_ecr_repository" "auth" {

  name = "auth-service"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

}

resource "aws_ecr_repository" "flag" {

  name = "flag-service"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

}

resource "aws_ecr_repository" "targeting" {

  name = "targeting-service"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

}

resource "aws_ecr_repository" "evaluation" {

  name = "evaluation-service"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

}

resource "aws_ecr_repository" "analytics" {

  name = "analytics-service"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

}
resource "aws_dynamodb_table" "analytics" {
  name         = "ToggleMasterAnalytics"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "eventId"

  attribute {
    name = "eventId"
    type = "S"
  }

  tags = {
    Name = "ToggleMasterAnalytics"
  }
}
resource "aws_sqs_queue" "events" {
  name = "togglemaster-events"

  tags = {
    Name = "togglemaster-events"
  }
}
