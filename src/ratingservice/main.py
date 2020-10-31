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
from flask import Flask, jsonify, request
from psycopg2 import pool


# If `entrypoint` is not defined in app.yaml, App Engine will look for an app
# called `app` in `main.py`.
app = Flask(__name__)
if (os.environ.get('DB_USERNAME') == None or os.environ.get('DB_PASSWORD') == None
        or os.environ.get('DB_NAME') == None or os.environ.get('DB_HOST') == None):
    exit(1)


def getConnection():
    if db_connection_pool == None:
        cfg = {
            'user': os.environ.get('DB_USERNAME'),
            'password': os.environ.get('DB_PASSWORD'),
            'database': os.environ.get('DB_NAME'),
            'host': os.environ.get('DB_HOST')
        }
        max_connections = int(os.getenv("MAX_DB_CONNECTIONS", "10"))
        db_connection_pool = pool.SimpleConnectionPool(
            minconn=1, maxconn=max_connections, **cfg)
    return db_connection_pool.getconn()


def makeError(code, message):
    result = jsonify({'error': message})
    result.status_code = code
    return result


def makeResult(data):
    result = jsonify(data)
    result.status_code = 200
    return result

#
# APIs
#


@app.route('/rating', methods=['GET'])
def getRating(id):
    eid = request.form['id']
    if eid == None or eid == "":
        return makeError(400, "invalid entity id")

    conn = getConnection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT rating FROM ratings WHERE eid='{}';".format(eid))
            result = cursor.fetchone()
            if result != None:
                result = makeResult({
                    'id': eid,
                    'rating': str(result)
                })
            else:
                resp = makeError(400, "invalid entity id")
        conn.commit()
    except:
        resp = makeError(500, 'DB error')
    finally:
        connpool.putconn(conn)
    return resp


@app.route('/rating', methods=['POST'])
def postRating():
    eid = request.form['id']
    if eid == None or eid == "":
        return makeError(400, "invalid entity id")
    rating_str = request.form['rating']
    if rating_str == None or rating_str == "" or :
        return makeError(400, "invalid rating")
    try:
        rating = int(rating_str)
        if rating < 1 or rating > 5:
            return makeError(400, "invalid rating")
    except ValueError:
        return makeError(400, "invalid rating")

    conn = getConnection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("INSERT INTO votes (eid, rating) VALUES ('{0}', {1});".format(
                eid, rating))
            resp = makeResult({})
        conn.commit()
    except:
        resp = makeError(500, 'DB error')
    finally:
        connpool.putconn(conn)
    return resp


@app.route('/ratings', methods=['PATCH'])
def aggregateRatings():
    eids = request.form.getlist('ids')
    if eids == None or len(eids) != 1:
        return makeError(400, "invalid list of entity ids")
    if eids[0] != "*":
        return makeError(400, "invalid list of entity ids")

    conn = getConnection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("UPDATE votes SET in_process=TRUE;")
            cursor.execute(
                "UPDATE ratings AS r SET "
                "rating=(r.rating*r.votes/(r.votes+v.votes))+(v.avg_rating*v.votes/(r.votes+v.votes)), "
                "votes=r.votes+v.votes "
                "FROM (SELECT eid, ROUND(AVG(rating),4) AS avg_rating, COUNT(eid) AS votes FROM votes WHERE in_process=TRUE GROUP BY eid) AS v "
                "WHERE r.eid = v.eid;")
            cursor.execute("DELETE FROM votes WHERE in_process=TRUE;")
            resp = makeResult({})
        conn.commit()
    except:
        resp = makeError(500, 'DB error')
    finally:
        connpool.putconn(conn)
    return resp


if __name__ == "__main__":
    # Used when running locally only. When deploying to Google App
    # Engine, a webserver process such as Gunicorn will serve the app. This
    # can be configured by adding an `entrypoint` to app.yaml.
    app.run(host="localhost", port=8080, debug=True)
