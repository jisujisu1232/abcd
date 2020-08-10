#data "aws_ami" "amazon-linux" {
#  most_recent = true
#  owners      = ["amazon"]
#  filter {
#    name   = "owner-alias"
#    values = ["amazon"]
#  }
#  filter {
#    name   = "name"
#    values = ["amzn-ami-hvm*"]
#  }
#}

data "aws_region" "current" {}

locals {
  nginx-userdata = <<NGINXUSERDATA
#!/bin/bash
sudo yum install aws-kinesis-agent -y

cat << EOF > /etc/aws-kinesis/agent.json
{
  "cloudwatch.endpoint": "monitoring.${data.aws_region.current.name}.amazonaws.com",
  "kinesis.endpoint": "kinesis.${data.aws_region.current.name}.amazonaws.com",
   "flows": [
        {
            "filePattern": "/var/log/nginx/access.log",
            "kinesisStream": "${aws_kinesis_stream.stream.name}",
            "maxBufferAgeMillis": 60000
        }
   ]
}
EOF
sudo service aws-kinesis-agent start
sudo yum install nginx -y
sudo service nginx start
chmod 777 /var/log/nginx /var/log/nginx/*
sudo chkconfig nginx on
sudo chkconfig aws-kinesis-agent on
NGINXUSERDATA
}

resource "aws_instance" "nginx" {
  #ami                    = "${data.aws_ami.amazon-linux.id}"
  ami                    = var.instance_ami
  instance_type          = "${var.nginx_instance_type}"
  key_name               = "${var.nginx_admin_instance_key}"
  vpc_security_group_ids = ["${aws_security_group.nginx.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.nginx_profile.name}"
  associate_public_ip_address = true
  subnet_id              = "${var.nginx_subnet}"
  user_data_base64       = "${base64encode(local.nginx-userdata)}"
  tags = "${
    map(
      "Name", "nginx-${var.stage}-pub"
    )
  }"
  depends_on             = ["aws_kinesis_stream.stream"]
}

resource "aws_security_group" "nginx" {
  name        = "nginx-${var.stage}-sg"
  description = "nginx-${var.stage} Security Group"
  vpc_id      = "${var.vpc_id}"

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group_rule" "user_to_db" {
  description       = "nginx-${var.stage} for User"
  security_group_id = "${aws_security_group.nginx.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
  type              = "ingress"
}


resource "aws_security_group_rule" "admin_to_db_ssh" {
  description       = "nginx-${var.stage} for Admin SSH"
  security_group_id = "${aws_security_group.nginx.id}"
  cidr_blocks       = "${var.nginx_admin_cidrs}"
  protocol          = "tcp"
  from_port         = "22"
  to_port           = "22"
  type              = "ingress"
}


resource "aws_iam_role" "nginx_role" {
  name = "nginx_role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "nginx_profile" {
  name = "nginx_profile_${var.stage}"
  role = "${aws_iam_role.nginx_role.name}"
}


resource "aws_iam_role_policy" "nginx_policy" {
  name = "nginx_policy_${var.stage}"
  role = "${aws_iam_role.nginx_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "cloudwatch:PutMetricData",
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "kinesis:PutRecord",
                "kinesis:PutRecords"
            ],
            "Resource": [
                "${aws_kinesis_stream.stream.arn}",
                "${aws_kinesis_stream.stream.arn}/*"
            ]
        }
    ]
}
EOF
}
