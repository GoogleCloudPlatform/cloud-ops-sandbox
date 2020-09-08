resource "google_app_engine_standard_app_version" "ratingservice_v1" {
  version_id = "v1"
  service    = "ratingservice"
  runtime    = "python38"

  entrypoint {
    shell = "gunicorn -b :8080 main:app"
  }

  deployment {
    zip {
      # Need to zip source code and upload to GCS
      source_url = "https://storage.googleapis.com/${var.bucket_name}/ratingservice_code.zip"
    }
  }

  env_variables = {
    CLOUD_SQL_DATABASE_NAME = google_sql_database_instance.master.name
    CLOUD_SQL_USERNAME = google_sql_user.default.name
    CLOUD_SQL_PASSWORD = google_sql_user.default.password
    CLOUD_SQL_CONNECTION_NAME = google_sql_database_instance.master.connection_name
  }

  basic_scaling {
    max_instances = 3
  }

  delete_service_on_destroy = true
}

resource "null_resource" "populate_db" {
  provisioner "local-exec" {
    # need to pass env vars
    command = "python3 install.py"
  }

  depends_on = [google_app_engine_standard_app_version.ratingservice_v1]
}