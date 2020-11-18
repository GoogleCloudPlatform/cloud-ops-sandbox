runtime: python38
env: standard
service: ${service_name}
entrypoint: uwsgi --http-socket :8080 --wsgi-file main.py --callable app --master --processes 1 --threads ${max_connections}
env_variables:
    DB_HOST: '${db_host}'
    DB_NAME: '${db_name}'
    DB_USERNAME: '${db_username}'
    DB_PASSWORD: '${db_password}'
    MAX_DB_CONNECTIONS: ${max_connections}
basic_scaling:
  max_instances: 10
  idle_timeout: 10m
