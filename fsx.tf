resource "aws_security_group" "circleci-fsx-sg" {
  name        = "dev-circleci-fsx-sg"
  description = "Allows access to FSx volumes from CircleCI Agents"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "from-linux-runners" {
  type              = "ingress"
  protocol          = "all"
  from_port         = -1
  to_port           = -1
  source_security_group_id = aws_security_group.circleci-linux-runners-sg.id
  security_group_id = aws_security_group.circleci-fsx-sg.id
}

resource "aws_security_group_rule" "from-windows-runners" {
  type              = "ingress"
  protocol          = "all"
  from_port         = -1
  to_port           = -1
  source_security_group_id = aws_security_group.circleci-windows-runners-sg.id
  security_group_id = aws_security_group.circleci-fsx-sg.id
}

resource "aws_fsx_openzfs_file_system" "circleci-fsx" {
  storage_capacity    = var.fsx.storage_capacity
  subnet_ids          = [var.subnet_ids[0]]
  deployment_type     = var.fsx.deployment_type
  throughput_capacity = var.fsx.throughput_capacity

  security_group_ids = [aws_security_group.circleci-fsx-sg.id]

  weekly_maintenance_start_time = "7:04:00"

  root_volume_configuration {
    nfs_exports {
      client_configurations {
        clients = var.fsx.client_configurations.clients
        options = split(",", var.fsx.client_configurations.options)
      }
    }
    data_compression_type = "ZSTD"
  }
}