resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "random_id" "db_password" {
  byte_length = 4
}

resource "google_sql_database_instance" "master" {
  name             = "master-instance-${random_id.db_name_suffix.hex}"
  database_version = "POSTGRES_12"
  region           = "us-west2"

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_user" "default" {
  name     = "postgres"
  password = random_id.db_password.hex
  instance = google_sql_database_instance.master.name
}