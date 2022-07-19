variable "min_size" {
  type = number
  default = 0
}
variable "max_size" {
  type = number
  default = 1
}

variable "desired_capacity" {
  type = number
  default = 0
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
  default = "c5.large"
}

variable "key_name" {
  type = string
  default = "gintini-aws-windows"
}

variable "name" {
  type = string
  default = "CircleCI Runner"
}

variable "user_data" {
  type = string
  default = ""
}

variable "iam_instance_profile_arn" {
  type = string
  default = ""
}

variable "vpc_security_group_ids" {
  type = list(string)
  default = []
}

variable "block_device_mappings" {
  type = list(object({
    device_name = string
    ebs = object({
      volume_size = number
    })
  }))
  default = []
}

variable "spot_instance" {
  type = bool
  default = true
}

variable "tag_specifications" {
  type = list(object({
    resource_type = string
    tags = map(any)
  }))
  default = []
}

variable "tags" {
  type = map(any)
  default = {} 
}

variable "asg_tags" {
  type = list(object({
    key = string
    propagate_at_launch = bool
    value = string
  }))
  default = []
}

variable "subnet_ids" {
  type = list(string)
  default = []
}

variable "scale_in_recurrence" {
  type = string
  default = "0 20 * * MON-FRI"
}

variable "scale_out_recurrence" {
  type = string
  default = "0 6 * * MON-FRI"
}