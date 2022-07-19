locals {
  security_group_ids = {
    "windows" = aws_security_group.circleci-windows-runners-sg.id
    "linux" = aws_security_group.circleci-linux-runners-sg.id
  }
}

module "circleci-runners" {
  for_each = {
    for index, runner in var.runners:
    runner.name => runner
  }

  source = "./modules/runner"

  name = each.value.name
  
  instance_type = each.value.instance_type
  min_size = each.value.asg.min_size
  max_size = each.value.asg.max_size
  ami = each.value.ami

  user_data = base64encode(templatefile("${path.module}/${each.value.os}-user-data.tpl", {
    auth_token   = var.circleci_auth_tokens[each.value.name]
    fsx_dns_name = aws_fsx_openzfs_file_system.circleci-fsx.dns_name
    asg_name     = each.value.name
  }))

  block_device_mappings = [{
    device_name = "/dev/sda1"
    ebs = {
      volume_size = each.value.root_volume_size
    }
  }]

  spot_instance = each.value.spot_instance

  vpc_security_group_ids = [
    local.security_group_ids[each.value.os]
  ]

  subnet_ids = var.subnet_ids

  asg_tags = [
    {
      key                 = "Name"
      propagate_at_launch = true
      value               = "CircleCI Runner - ${each.value.os}"
    },
    {
      key                 = "Role"
      propagate_at_launch = true
      value               = "CircleCI Runner - ${each.value.os}"
    },
    {
      key                 = "resource-class"
      propagate_at_launch = true
      value               = each.value.name
    }
  ]
}