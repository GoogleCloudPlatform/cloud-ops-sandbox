output "service_url" {
  value = "https://ratingservice-dot-${length(google_app_engine_application.app) > 0 ? google_app_engine_application.app[0].default_hostname : data.external.app_engine_state.result.application_domain}"
}
