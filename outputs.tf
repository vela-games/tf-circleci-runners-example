output "runners_asg_arns" {
  value = [
    for runner in module.circleci-runners : runner.asg_arn
  ]
}