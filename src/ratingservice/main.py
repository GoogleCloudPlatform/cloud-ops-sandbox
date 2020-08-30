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
import psycopg2

db_user = os.environ.get('CLOUD_SQL_USERNAME')
db_password = os.environ.get('CLOUD_SQL_PASSWORD')
db_name = os.environ.get('CLOUD_SQL_DATABASE_NAME')
db_connection_name = os.environ.get('CLOUD_SQL_CONNECTION_NAME')

host = '/cloudsql/{}'.format(db_connection_name)

def init():
    products = ['OLJCESPC7Z','66VCHSJNUP','1YMWWN1N4O','L9ECAV7KIM','2ZYFJ3GM2N','0PUK6V6EV0','LS4PSXUNUM','9SIQT8TOJO', '6E92ZMYYFZ']
    conn = psycopg2.connect(dbname=db_name, user=db_user, password=db_password, host=host)
    with conn.cursor() as cursor:
        cursor.execute("SELECT EXISTS(SELECT * FROM information_schema.tables WHERE table_name = 'ratings');")
        result = cursor.fetchone()
        if not result[0]:
            cursor.execute("CREATE TABLE ratings (product_id varchar(20) PRIMARY KEY, sum_of_score int DEFAULT 0, count_of_score int DEFAULT 0);")
            for product in products:
                cursor.execute("INSERT INTO ratings (product_id) VALUES ('{}');".format(product))
    conn.commit()
    conn.close()

app = Flask(__name__)
init()

@app.route('/getRating/<id>')
def getRating(id):
    conn = psycopg2.connect(dbname=db_name, user=db_user, password=db_password, host=host)
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT product_id, sum_of_score, count_of_score FROM ratings WHERE product_id='{}';".format(id))
            result = cursor.fetchone()
        rating = result[1] / result[2] if result[2] != 0 else 0
        conn.commit()
    finally:
        conn.close()
    return str(rating)

@app.route('/rate/<id>/<score>')
def rate(id, score):
    conn = psycopg2.connect(dbname=db_name, user=db_user, password=db_password, host=host)
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT product_id, sum_of_score, count_of_score FROM ratings WHERE product_id='{}';".format(id))
            result = cursor.fetchone()
            cursor.execute("UPDATE ratings SET sum_of_score={0}, count_of_score={1} WHERE product_id='{2}';".format(int(score) + result[1], 1 + result[2], id))
        conn.commit()
    finally:
        conn.close()    
    return 'Success'

@app.route('/')
def index():
    return "Hello!"

