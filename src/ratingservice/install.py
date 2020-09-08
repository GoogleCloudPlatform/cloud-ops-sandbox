import os
import psycopg2

# create table
def init():
    try:
        db_user = os.environ.get('CLOUD_SQL_USERNAME')
        db_password = os.environ.get('CLOUD_SQL_PASSWORD')
        db_name = os.environ.get('CLOUD_SQL_DATABASE_NAME')
        db_connection_name = os.environ.get('CLOUD_SQL_CONNECTION_NAME')
        host = '/cloudsql/{}'.format(db_connection_name)
        conn = psycopg2.connect(dbname=db_name, user=db_user, password=db_password, host=host)
        with conn.cursor() as cursor:
            cursor.execute("SELECT EXISTS(SELECT * FROM information_schema.tables WHERE table_name = 'ratings');")
            result = cursor.fetchone()
            if not result[0]:
                cursor.execute("CREATE TABLE ratings (id SERIAL PRIMARY KEY, product_id varchar(20) NOT NULL, score int DEFAULT 0);")
        conn.commit()
    finally:
        conn.close()

init()