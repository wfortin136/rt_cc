resource "aws_security_group" "piv-app" {
  name        = "Pivotal App"
  description = "Security Group for Pivotal App ECS instances"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["4.15.207.97/32"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["4.15.207.97/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "piv-app"
  }
}

resource "aws_launch_configuration" "piv-app-v1" {
  name                 = "piv-app-v1"
  image_id             = "ami-04351e12"
  instance_type        = "t2.micro"
  key_name             = "priv_account_key"
  security_groups      = ["${aws_security_group.piv-app.id}"]
  user_data            = "${base64encode(file("user_data/pivotal.ud"))}"
  enable_monitoring    = false
  ebs_optimized        = false

  lifecycle {
    ignore_changes = ["image_id", "user_data"]
  }
}

resource "aws_launch_configuration" "piv-app-v2" {
  name                 = "piv-app-v2"
  image_id             = "ami-04351e12"
  instance_type        = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.ecsProfile.name}"
  key_name             = "priv_account_key"
  security_groups      = ["${aws_security_group.piv-app.id}"]
  user_data            = "${base64encode(file("user_data/pivotal.ud"))}"
  enable_monitoring    = false
  ebs_optimized        = false

  lifecycle {
    ignore_changes = ["image_id", "user_data"]
  }
}

resource "aws_autoscaling_group" "piv-app-scaling" {
  availability_zones        = ["us-east-1a"]
  desired_capacity          = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  launch_configuration      = "${aws_launch_configuration.piv-app-v2.name}"
  max_size                  = 1
  min_size                  = 1
  name                      = "piv-app-scaling"

  tag {
    key                 = "Name"
    value               = "piv-app"
    propagate_at_launch = true
  }
}

resource "aws_ecs_cluster" "piv-app" {
  name = "piv-app"
}

resource "aws_ecs_task_definition" "piv-app" {
  family = "piv-app"

  container_definitions = <<DEFINITION
[
	{
		"volumesFrom": [],
		"memory": 500,
		"portMappings": [
			{
				"hostPort": 80,
				"containerPort": 4567,
				"protocol": "tcp"
			}
		],
		"essential": true,
		"name": "piv-app",
		"environment": [],
		"image": "wfortin136/rt_cc:latest",
		"cpu": 0
	}
]
DEFINITION
}

resource "aws_ecs_service" "piv-app" {
  name                               = "piv-app"
  cluster                            = "${aws_ecs_cluster.piv-app.id}"
  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.piv-app.family}:${aws_ecs_task_definition.piv-app.revision}"

  lifecycle {
    ignore_changes = ["task_definition"]
  }
}

resource "aws_security_group" "piv-rds" {  
  name = "piv-rds"

  description = "RDS postgres servers (terraform-managed)"
  vpc_id = "vpc-9d81a4e4"

	# Only allow traffic from cidr block of vpc
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
		cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "piv" {
  allocated_storage        = 5
  storage_type             = "gp2"
  engine                   = "postgres"
  engine_version           = "9.6.3"
  instance_class           = "db.t2.micro"
  name                     = "rtchallenge"
  username                 = "user1"
  password                 = "password1"
  vpc_security_group_ids   = ["${aws_security_group.piv-rds.id}"]
  skip_final_snapshot      = true
}

resource "aws_iam_instance_profile" "ecsProfile" {
  name  = "ecsProfile"
  role = "${aws_iam_role.ecs-role.name}"
}

resource "aws_iam_role" "ecs-role" {
    name = "ecs-role"
    assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs-policy" {
  name = "ecs-policy"
  role     = "${aws_iam_role.ecs-role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:UpdateContainerInstancesState",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

