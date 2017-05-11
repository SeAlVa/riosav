from flask import Flask, request
from sqlalchemy import create_engine
import json
import re

app = Flask(__name__)
db = create_engine("postgresql+psycopg2://{username}:{password}@{hostname}/{databasename}".format(
    username="xx",
    password="yy",
    hostname="zz.elephantsql.com",
    databasename="xx",
))
@app.route('/api/leads')
def fetchLeads():
    
    uuid_pagination = request.args.get('last_uuid',default='0')
    limit = request.args.get('limit', default='100')
    where_conditions = []
    
    if uuid_offset is None:
        uuid_pattern = re.compile("^[a-f0-9]*$")
        if uuid_pattern.match(uuid_offset):
            where_conditions.append("uuid > '" + uuid_offset + "'")
        
    if not re.compile("^[0-9]*$").match(limit):
        limit = '100'


    try :
        if not request.authorization is None or request.authorization.username != 'xx' or request.authorization.password != 'yy':
            
            connection = db.connect() # connect to database
            query = connection.execute("SELECT * FROM leads {where_clause} ORDER BY uuid limit {limit}".format(
                where_clause=("WHERE " + ' AND '.join(where_conditions)) if len(where_conditions) > 0 else "",
                limit=limit
            ))
            connection.close()

            return json.dumps([dict(r) for r in query])
        else:
            return '{"error":"Not Authorized"}'
    except sqlalchemy.exc.OperationalError:
        return '{"error":"Can\'t connect"}'
