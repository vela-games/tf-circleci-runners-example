resource "aws_security_group" "circleci-linux-runners-sg" {
  name        = "linux-circleci-runners"
  description = "Allows access to Linux circleci runners"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "linux-ssh" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.circleci-linux-runners-sg.id
}

resource "aws_security_group_rule" "all-egress-linux" {
  type              = "egress"
  protocol          = "all"
  from_port         = -1
  to_port           = -1
  cidr_blocks       = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.circleci-linux-runners-sg.id
}

resource "aws_security_group" "circleci-windows-runners-sg" {
  name        = "circleci-windows-agent"
  description = "Allow access to Windows circleci runners from valid ranges"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "all-egress-windows" {
  type              = "egress"
  protocol          = "all"
  from_port         = -1
  to_port           = -1
  cidr_blocks       = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.circleci-windows-runners-sg.id
}

resource "aws_security_group_rule" "windows-ssh" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.circleci-windows-runners-sg.id
}

resource "aws_security_group_rule" "rdp" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3389
  to_port           = 3389
  cidr_blocks       = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.circleci-windows-runners-sg.id
}

resource "aws_security_group_rule" "winrm" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 5985
  to_port           = 5986
  cidr_blocks       = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.circleci-windows-runners-sg.id
}
