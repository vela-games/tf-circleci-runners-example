runners = [{
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