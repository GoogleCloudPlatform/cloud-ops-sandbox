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
from psycopg2 import pool, DatabaseError, IntegrityError


# If `entrypoint` is not defined in app.yaml, App Engine will look for an app
# called `app` in `main.py`.
db_connection_pool = None

app = Flask(__name__)
if (os.environ.get('DB_USERNAME') == None or os.environ.get('DB_PASSWORD') == None
        or os.environ.get('DB_NAME') == None or os.environ.get('DB_HOST') == None):
    print('error: environment vars DB_USERNAME, DB_PASSWORD, DB_NAME and DB_HOST must be defined.')
    exit(1)


def getConnection():
    global db_connection_pool
    if db_connection_pool == None:
        cfg = {
            'user': os.environ.get('DB_USERNAME'),
            'password': os.environ.get('DB_PASSWORD'),
            'database': os.environ.get('DB_NAME'),
            'host': os.environ.get('DB_HOST')
        }
        max_connections = int(os.getenv("MAX_DB_CONNECTIONS", "10"))
        try:
            db_connection_pool = pool.SimpleConnectionPool(
                minconn=1, maxconn=max_connections, **cfg)
        except (Exception, DatabaseError) as error:
            print(error)
            return None

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


@app.route('/rating/<eid>', methods=['GET'])
def getRatingById(eid):
    if eid == None or eid == "":
        return makeError(400, "malformed entity id")

    conn = getConnection()
    if conn == None:
        return makeError(500, 'failed to connect to DB')
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT rating, votes FROM ratings WHERE eid=%s", (eid,))
            result = cursor.fetchone()
        conn.commit()
        if result != None:
            return makeResult({
                'id': eid,
                'rating': result[0],
                'votes': result[1]
            })
        else:
            return makeError(404, "invalid entity id")
    except:
        resp = makeError(500, 'DB error')
    finally:
        db_connection_pool.putconn(conn)


@app.route('/rating', methods=['POST'])
def postRating():
    data = request.get_json()
    if data == None:
        return makeError(400, "missing json payload")

    eid = str(data['id'])
    if eid == None or eid == "":
        return makeError(400, "malformed entity id")
    rating_str = str(data['rating'])
    if rating_str == None or rating_str == "":
        return makeError(400, "malformed rating")
    if not rating_str.isdigit():
        return makeError(400, "rating should be non negative number")
    rating = int(rating_str)
    if rating < 1 or rating > 5:
        return makeError(400, "rating should be non negative number")

    conn = getConnection()
    if conn == None:
        return makeError(500, 'failed to connect to DB')
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "INSERT INTO votes (eid, rating) VALUES (%s, %s)", (eid, rating))
        conn.commit()
        return makeResult({})
    except IntegrityError:
        return makeError(404, 'invalid entity id')
    except:
        return makeError(500, 'DB error')
    finally:
        db_connection_pool.putconn(conn)


@ app.route('/recollect', methods=['GET'])
def aggregateRatings():
    conn = getConnection()
    if conn == None:
        return makeError(500, 'failed to connect to DB')
    try:
        with conn.cursor() as cursor:
            cursor.execute("UPDATE votes SET in_process=TRUE")
            cursor.execute(
                "UPDATE ratings AS r SET "
                "rating=(r.rating*r.votes/(r.votes+v.votes))+(v.avg_rating*v.votes/(r.votes+v.votes)), "
                "votes=r.votes+v.votes "
                "FROM (SELECT eid, ROUND(AVG(rating),4) AS avg_rating, COUNT(eid) AS votes FROM votes WHERE in_process=TRUE GROUP BY eid) AS v "
                "WHERE r.eid = v.eid")
            cursor.execute("DELETE FROM votes WHERE in_process=TRUE")
        conn.commit()
        return makeResult({})
    except:
        return makeError(500, 'DB error')
    finally:
        db_connection_pool.putconn(conn)
    return resp


if __name__ == "__main__":
    # Used when running locally only. When deploying to Google App
    # Engine, a webserver process such as Gunicorn will serve the app. This
    # can be configured by adding an `entrypoint` to app.yaml.
    app.run(host="localhost", port=8080, debug=True)
