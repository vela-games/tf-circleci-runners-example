variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
  default = []
}

variable "fsx" {
  type = object({
    storage_capacity = number
    deployment_type = string
    throughput_capacity = number
    client_configurations = map(string)
  })
  default = {
    storage_capacity = 1000
    deployment_type  = "SINGLE_AZ_1"
    throughput_capacity = 2048
    client_configurations = {
      clients = "*"
      options = "rw,crossmnt,all_squash"
    }
  }
}

variable "circleci_auth_tokens" {
  type = map(string)
  sensitive = true
}

variable "runners" {
  type = list(object({
    name = string
    instance_type = string
    os = string
    root_volume_size = number
    spot_instance = bool
    asg = object({
      min_size = number
      max_size = number
      desired_capacity = number
    })
    ami = string
    key_name = string
    scale_out_recurrence = string
    scale_in_recurrence = string
  }))
  default = [{
    name = "namespace/linux-resource-class"
    instance_type = "c6a.8xlarge"
    os = "windows"
    ami = "ami-id"
    root_volume_size = 2000
    spot_instance = true
    asg = {
      min_size = 0
      max_size = 10
      desired_capacity = 0
    }
    key_name = "key-name"
    scale_out_recurrence = "0 6 * * MON-FRI"
    scale_in_recurrence = "0 20 * * MON-FRI"
  },{
    name = "namespace/windows-resource-class"
    instance_type = "c6a.8xlarge"
    os = "linux"
    root_volume_size = 2000
    spot_instance = true
    ami = "ami-id"
    asg = {
      min_size = 0
      max_size = 10
      desired_capacity = 0
    }
    key_name = "key-name"
    scale_out_recurrence = "0 6 * * MON-FRI"
    scale_in_recurrence = "0 20 * * MON-FRI"
  }]
}