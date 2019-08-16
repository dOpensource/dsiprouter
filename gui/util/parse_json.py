'''
@Summary: Contains methods for parsing json data.
@Author: devopsec
'''
from flask.json import JSONEncoder
from datetime import date
import json

def json_encode(data):
    try:
        return json.dumps(data)
    except:
        raise ValueError('Malformed JSON')

def json_decode(data):
    try:
        return json.loads(data)
    except:
        raise ValueError('Malformed JSON')



class CustomJSONEncoder(JSONEncoder):
    def default(self, obj):
        try:
            if isinstance(obj, date):
                return obj.isoformat()
            iterable = iter(obj)
        except TypeError:
            pass
        else:
            return list(iterable)
        return JSONEncoder.default(self, obj)
