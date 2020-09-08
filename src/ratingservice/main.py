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
import json
from flask import Flask,Response,jsonify
from psycopg2 import pool,extensions

connpool = None

# connect to cloud sql
def initConnection():
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
    connpool = pool.ThreadedConnectionPool(minconn=1, maxconn=10, **db_config)
    return connpool

# read product ids
def read_products():
    res = []
    with open('products.json') as f:
        data = json.load(f)
        for product in data['products']:
            res.append(product['id'])
    return res

# create and populate table
def populate_database():
    try:
        products = read_products()
        conn = connpool.getconn()
        with conn.cursor() as cursor:
            cursor.execute("SELECT EXISTS(SELECT * FROM information_schema.tables WHERE table_name = 'ratings');")
            result = cursor.fetchone()
            if not result[0]:
                cursor.execute("CREATE TABLE ratings (id SERIAL PRIMARY KEY, product_id varchar(20) NOT NULL, score int DEFAULT 0);")
                for product in products:
                    cursor.execute("INSERT INTO ratings (product_id, score) VALUES ('{}', 5);".format(product))
        conn.commit()
    finally:
        connpool.putconn(conn)

app = Flask(__name__)
connpool = initConnection()
populate_database()

@app.route('/getRating/<id>')
def getRating(id):
    conn = connpool.getconn()
    resp = None
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT AVG(score), COUNT(*) FROM ratings WHERE product_id='{}';".format(id))
            result = cursor.fetchone()
            if result[1] > 0:
                data = {
                    'status' : 'success',
                    'rating' : str(result[0]),
                    'count'  : str(result[1])
                }
                resp = jsonify(data)
                resp.status_code = 200
            else:
                data = {
                    'status' : 'fail',
                    'message' : 'Product does not exist: {}'.format(id)
                }     
                resp = jsonify(data)
                resp.status_code = 404   
        conn.commit()    
    except:
        data = {
            'status'  : 'fail',
            'message' : 'Internal server error'
        }
        resp = jsonify(data)
        resp.status_code = 500
        return resp
    finally:
        connpool.putconn(conn)
    return resp

@app.route('/rate/<id>/<score>')
def rate(id, score):
    conn = connpool.getconn()
    resp = None
    try:
        with conn.cursor() as cursor:
            cursor.execute("INSERT INTO ratings (product_id, score) VALUES ('{0}', {1});".format(id, score))
            data = {
                'status' : 'success'
            }
            resp = jsonify(data)
            resp.status_code = 200
        conn.commit()
    except:
        data = {
            'status'  : 'fail',
            'message' : 'Internal server error'
        }
        resp = jsonify(data)
        resp.status_code = 500
        return resp
    finally:
        connpool.putconn(conn)
    return resp

@app.route('/')
def hello():
    return 'hello!'