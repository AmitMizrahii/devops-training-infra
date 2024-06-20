locals {
  project_name = "devops-training-infra"

  common_tags = {
    Creator = "Amit"
    project = local.project_name
  }
}
