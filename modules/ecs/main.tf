# ECS Module - Following CIS v4 controls and AWS Well-Architected Framework

# ECS Cluster with Container Insights enabled
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cluster"
  })
}

# CloudWatch Log Group for ECS tasks
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.logs_kms_key_arn
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-logs"
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn           = var.task_role_arn
  
  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-container"
      image = "${var.ecr_repository_url}:latest"
      
      essential = true
      
      portMappings = [
        {
          containerPort = var.app_port
          protocol      = "tcp"
        }
      ]
      
      # Environment variables from Parameter Store
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/db-password"
        }
      ]
      
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "APP_PORT"
          value = tostring(var.app_port)
        }
      ]
      
      # Logging configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      # Health check
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${var.app_port}${var.health_check_path} || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      
      # Security - run as non-root user
      user = "1000:1000"
      
      # Resource limits
      ulimits = [
        {
          name      = "nofile"
          softLimit = 65536
          hardLimit = 65536
        }
      ]
    }
  ])
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-task"
  })
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  
  platform_version = "1.4.0"  # Latest stable version
  
  network_configuration {
    security_groups  = var.security_group_ids
    subnets          = var.private_subnet_ids
    assign_public_ip = false  # CIS 5.3 - Tasks in private subnets
  }
  
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${var.project_name}-container"
    container_port   = var.app_port
  }
  
  # Deployment configuration
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  
  # Service discovery (optional)
  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.main[0].arn
    }
  }
  
  depends_on = [var.target_group_arn]
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-service"
  })
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  
  tags = var.tags
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "${var.project_name}-${var.environment}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "${var.project_name}-${var.environment}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Service Discovery (optional)
resource "aws_service_discovery_private_dns_namespace" "main" {
  count = var.enable_service_discovery ? 1 : 0
  
  name        = "${var.project_name}-${var.environment}.local"
  description = "Service discovery namespace for ${var.project_name}-${var.environment}"
  vpc         = var.vpc_id
  
  tags = var.tags
}

resource "aws_service_discovery_service" "main" {
  count = var.enable_service_discovery ? 1 : 0
  
  name = "${var.project_name}-${var.environment}"
  
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main[0].id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
    
    routing_policy = "MULTIVALUE"
  }
  
  tags = var.tags
}

# Secrets Manager secret for database password
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}/${var.environment}/db-password"
  description             = "Database password for ${var.project_name}-${var.environment}"
  kms_key_id             = var.secrets_kms_key_id
  recovery_window_in_days = 7
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-password"
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    password = "change-me-in-production"
  })
  
  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}