# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
from flask import Flask
import psycopg2.pool

db_user = os.environ.get('CLOUD_SQL_USERNAME')
db_password = os.environ.get('CLOUD_SQL_PASSWORD')
db_name = os.environ.get('CLOUD_SQL_DATABASE_NAME')
db_connection_name = os.environ.get('CLOUD_SQL_CONNECTION_NAME')

host = '/cloudsql/{}'.format(db_connection_name)
db_config = {
    'user': db_user,
    'password': db_password,
    'database': db_name,
    'host': host
}
connpool = psycopg2.pool.ThreadedConnectionPool(minconn=1, maxconn=10, **db_config)

app = Flask(__name__)

@app.route('/getRating/<id>')
def getRating(id):
    conn = connpool.getconn()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT AVG(score), COUNT(*) FROM ratings WHERE product_id='{}';".format(id))
            result = cursor.fetchone()
        conn.commit()
    finally:
        connpool.putconn(conn)

    return {
        'status' : 'success',
        'rating' : str(result[0]),
        'count'  : str(result[1])
    }

@app.route('/rate/<id>/<score>')
def rate(id, score):
    conn = connpool.getconn()
    try:
        with conn.cursor() as cursor:
            cursor.execute("INSERT INTO ratings (product_id, score) VALUES ('{0}', {1});".format(id, score))
        conn.commit()
    finally:
        connpool.putconn(conn)
    
    return {
        'status' : 'success'
    }
