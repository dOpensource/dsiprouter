'''
@summary: Provides methods for working with datetimes, timestamps, etc..
@author: devopsec
'''

import pytz
from datetime import datetime, timezone

def convert_ts(ts, millis=False, is_utc=False):
    '''
    convert timestamp to human readable format
    optionally keep up to microsecond precision
    if timestamp is utc format pass param is_utc=True
    '''

    # if ts is not in string format
    if not type(ts).__name__ == 'str':
        ts = str(ts)

    # if contains ts contains millis and millis is false, strip them #
    formatted_ts = None # create var above routine
    # TODO: add try catch error handling
    if len(ts) > 10:
        if millis == False:
            replace = len(ts) - 10
            ts = ts[:-replace]
            if is_utc == True:
                formatted_ts = datetime.fromtimestamp(int(ts), tz=pytz.utc).strftime('%Y-%m-%d %H:%M:%S')
            else:
                formatted_ts = datetime.fromtimestamp(int(ts)).strftime('%Y-%m-%d %H:%M:%S')

        else: # convert w/ millis and return
            if not '.' in ts: # needs . to distinguish millis
                ts = ts[0:10] + '.' + ts[10:]
            if is_utc == True:
                formatted_ts = datetime.fromtimestamp(float(ts), tz=pytz.utc).strftime('%Y-%m-%d %H:%M:%S.%f')
            else:
                formatted_ts = datetime.fromtimestamp(float(ts)).strftime('%Y-%m-%d %H:%M:%S.%f')
    else: # convert w/o millis and return
        if is_utc == True:
            formatted_ts = datetime.fromtimestamp(int(ts), tz=pytz.utc).strftime('%Y-%m-%d %H:%M:%S')
        else:
            formatted_ts = datetime.fromtimestamp(int(ts)).strftime('%Y-%m-%d %H:%M:%S')

    return formatted_ts

# DEBUG
# print(convert_ts("1486782196652"))
# print(convert_ts("1486782196"))
# print(convert_ts(1486782196.652655, millis=True))
# print(convert_ts("1486782196652655", millis=True))
# print(convert_ts("1486782196652655", is_utc=True))

# TODO: add try catch error handling
def utcnow(format="ts"):
    ''' returns time-aware utc datetime object or timestamp of current time/date
        @Param: format  -  defaults to timestamp, provide "dt" for datetime obj '''

    dt = datetime.now(tz=pytz.utc)
    if format == "dt":
        return dt
    else: # timestamp includes millis down to 6th decimal place
        ts = str(dt.timestamp())
        return ts.replace('.', '')

# DEBUG
# print(utcnow())
# print(utcnow("dt"))

# TODO add methods for converting to client local timezone dynamically
