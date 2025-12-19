# Security Groups Module - Following CIS v4 controls

# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load Balancer"
  
  # HTTP ingress (consider redirecting to HTTPS)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS ingress
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
    Type = "ALB"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# ECS Security Group
resource "aws_security_group" "ecs" {
  name_prefix = "${var.project_name}-${var.environment}-ecs-"
  vpc_id      = var.vpc_id
  description = "Security group for ECS tasks"
  
  # Egress for HTTPS (for pulling images, secrets, etc.)
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Egress for HTTP (if needed for health checks or external APIs)
  egress {
    description = "HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # DNS resolution
  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
    Type = "ECS"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# VPC Endpoint Security Group (for secure access to AWS services)
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-${var.environment}-vpce-"
  vpc_id      = var.vpc_id
  description = "Security group for VPC endpoints"
  
  ingress {
    description     = "HTTPS from ECS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpce-sg"
    Type = "VPCEndpoint"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Rules for cross-references (to avoid circular dependencies)
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = aws_security_group.alb.id
  description              = "ALB to ECS communication"
}

resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
  description              = "ECS from ALB communication"
}