locals {
  container_name = "amit-app-container"
}

resource "aws_security_group" "ecs_security_group" {
  vpc_id = aws_vpc.custom.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "ecs-security-group" })
}

resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = "amit-ecs-cluster"

  tags = merge(local.common_tags, {
    Name = "amit-ecs-cluster"
  })
}

resource "aws_ecr_repository" "my_repository" {
  name = "amit-app"
}



resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "amit-app"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = local.container_name
    image     = "248184751550.dkr.ecr.us-east-1.amazonaws.com/amit-app:latest"
    cpu       = 256
    memory    = 512
    essential = true

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/amit-log-group"
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs"
      }
    }
    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]
    environment = [
      {
        name  = "DB_HOST"
        value = var.db_end_point
      },
      {
        name  = "PG_URL"
        value = "postgresql://${var.db_credentials.username}:${var.db_credentials.password}@${var.db_end_point}"
      },
      {
        name  = "DB_USER"
        value = var.db_credentials.username
      },
      {
        name  = "DB_PASSWORD"
        value = var.db_credentials.password
      },
      {
        name  = "REDIS_HOST"
        value = aws_elasticache_cluster.redis.cache_nodes[0].address
      }
    ]
  }])
}


resource "aws_ecs_service" "my_service" {
  name            = "amit-service"
  cluster         = aws_ecs_cluster.my_ecs_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs_security_group.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = local.container_name
    container_port   = 8080
  }

  tags = merge(local.common_tags, { Name = "amit-ecs-service" })
}

resource "aws_lb" "my_lb" {
  name               = "amit-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_security_group.id]

  subnets = [
    aws_subnet.public.id,
    aws_subnet.public2.id
  ]

  tags = merge(local.common_tags, { Name = "amit-lb" })
}


resource "aws_lb_target_group" "my_target_group" {
  name        = "amit-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.custom.id
  target_type = "ip"
  health_check {
    path     = "/health"
    protocol = "http"
  }

  tags = merge(local.common_tags, { Name = "my-tg" })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "amit-ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}



resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/amit-log-group"
  retention_in_days = 7

  tags = local.common_tags
}
