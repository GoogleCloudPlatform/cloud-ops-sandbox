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
from flask import Flask,Response,jsonify
from psycopg2 import pool,extensions

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

app = Flask(__name__)
connpool = initConnection()

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
