# Creating this variable but leaving it empty means that the user will be
# prompted for a value when terraform is run
variable "external_ip" {
  type        = "string"
  description = "The external IP of the kubernetes cluster. Can be revealed by running kubectl get service frontend-external in Cloud CLI."
}

variable "project_id" {
  type        = "string"
  description = "The project id that was created by stackdriver sandbox."
}

variable "project_owner_email" {
	type	      = "string"
	description = "The email of the project owner."
}