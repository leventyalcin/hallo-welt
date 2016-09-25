/*
We do not like to expose any AWS creds, right?
Then we will use boto style with Terraform
For tests, you have to export standard AWS Env vars
Best practice is Jenkins and proper IAM roles for the
instance.
Good!
*/
provider "aws" {
  region     = "${var.aws_region}"
}


/*
we do not create a single instance without IAM role
*/

resource "aws_iam_role" "role" {
    name               = "${var.service_name}-${var.service_version}"
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

resource "aws_iam_role_policy" "policy" {
    name   = "${var.service_name}-${var.service_version}"
    role   = "${aws_iam_role.role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1455556909000",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        }
    ]
}
EOF
    depends_on = ["aws_iam_role.role"]
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name  = "${var.service_name}-${var.service_version}"
    roles = ["${aws_iam_role.role.name}"]

    depends_on = ["aws_iam_role.role", "aws_iam_role_policy.policy"]
}

resource "aws_security_group" "service" {
  name        = "${var.service_name}-${var.service_version}-instance"
  description = "${var.service_name}-${var.service_version}-instance"
  vpc_id      = "${var.vpc_id}"

  # SSH access
  # Bastion and VPN are welcome to SSH into
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # HTTP access
  ingress {
    from_port   = "${var.service_port}"
    to_port     = "${var.service_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # ICMP
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name       = "${var.service_name}-${var.service_version}-instance"
    service    = "${var.service_name}"
    version    = "${var.service_version}"
  }
}

resource "aws_security_group" "elb" {
  name        = "${var.service_name}-${var.service_version}-elb"
  description = "${var.service_name}-${var.service_version}-elb"
  vpc_id      = "${var.vpc_id}"

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name       = "${var.service_name}-${var.service_version}-elb"
    service    = "${var.service_name}"
    version    = "${var.service_version}"
  }
}

resource "aws_elb" "service" {
  name                      = "${var.service_name}"
  subnets                   = ["${split(",", var.public_subnet_ids)}"]
  security_groups           = ["${aws_security_group.elb.id}"]
  connection_draining       = true
  cross_zone_load_balancing = false

  listener {
    instance_port     = "${var.service_port}"
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 5
    target              = "HTTP:80/"
    interval            = 30
  }

  tags {
    Name         = "${var.service_name}-${var.service_version}-elb"
    service      = "${var.service_name}"
    version      = "${var.service_version}"
  }
}

data "template_file" "service_userdata" {
    template = "${file("userdata.sh.tpl")}"

    vars {
      dockerhub_account = "${var.dockerhub_account}"
      service_name      = "${var.service_name}"
      service_version   = "${var.service_version}"
      service_port      = "${var.service_port}"
    }
}

resource "aws_launch_configuration" "service" {
  name                        = "${var.service_name}-${var.service_version}"
  image_id                    = "${var.coreos_ami_id}"
  iam_instance_profile        = "${aws_iam_instance_profile.ec2_profile.name}"
  user_data                   = "${data.template_file.service_userdata.rendered}"
  instance_type               = "${var.instance_type}"
  associate_public_ip_address = false
  security_groups             = ["${aws_security_group.service.id}"]
  key_name                    = "${var.aws_key_name}"
}

resource "aws_autoscaling_group" "service" {
  name                 = "${var.service_name}-${var.service_version}"
  max_size             = "${var.service_asg_max}"
  min_size             = "${var.service_asg_max}"
  desired_capacity     = "${var.service_asg_max}"
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.service.name}"
  vpc_zone_identifier  = ["${split(",", var.private_subnet_ids)}"]
  load_balancers       = ["${aws_elb.service.name}"]
  tag {
    key                 = "Name"
    value               = "${var.service_name}-${var.service_version}"
    propagate_at_launch = "true"
  }
  tag {
    key                 = "service"
    value               = "${var.service_name}"
    propagate_at_launch = "true"
  }
  tag {
    key                 = "version"
    value               = "${var.service_version}"
    propagate_at_launch = "true"
  }
}

resource "aws_route53_record" "service" {
  zone_id = "${var.public_domain_zoneid}"
  name    = "${var.service_dns}"
  type    = "A"

  alias {
    name    = "${aws_elb.service.dns_name}"
    zone_id = "${aws_elb.service.zone_id}"
    evaluate_target_health = false
  }

  depends_on = ["aws_elb.service"]
}
