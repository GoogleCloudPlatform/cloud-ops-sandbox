module "loadgen" {
  source = "./loadgen"

  external_ip = data.external.terraform_vars.result.external_ip
  project_id = data.google_project.project.project_id
}