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
from flask import Flask,Response,jsonify,request
from psycopg2 import pool

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

# get rating of a product
@app.route('/rating/<id>', methods=['GET'])
def getRating(id):
    conn = connpool.getconn()
    resp = None
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT AVG(score), COUNT(*) FROM ratings WHERE product_id='{}';".format(id))
            result = cursor.fetchone()
            rating, count = result[0], result[1]
            if count > 0:
                # product exists
                resp = jsonify({
                    'status' : 'success',
                    'rating' : str(rating),
                    'count'  : str(count)
                })
                resp.status_code = 200
            else:
                # product not exists
                resp = jsonify({'error' : 'Product not found'.format(id)})
                resp.status_code = 404   
        conn.commit()    
    except:
        resp = jsonify({'error' : 'Error in database: Fail to get the rating of product {}'.format(id)})
        resp.status_code = 500
    finally:
        connpool.putconn(conn)
    return resp

# rate a product
@app.route('/rating', methods=['POST'])
def rate():
    conn = connpool.getconn()
    resp = None
    product_id = request.form['id']
    score = request.form['score']
    try:
        with conn.cursor() as cursor:
            cursor.execute("INSERT INTO ratings (product_id, score) VALUES ('{0}', {1});".format(product_id, score))
            resp = jsonify({'status' : 'success'})
            resp.status_code = 200
        conn.commit()
    except:
        resp = jsonify({'error' : 'Error in database: Fail to add a rating of product {}'.format(id)})
        resp.status_code = 500
    finally:
        connpool.putconn(conn)
    return resp
