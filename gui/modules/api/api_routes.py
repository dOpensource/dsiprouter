from flask import Blueprint, session, render_template,jsonify
from flask import Flask, render_template, request, redirect, abort, flash, session, url_for, send_from_directory
from sqlalchemy import case, func, exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from database import loadSession, Domain, DomainAttrs, dSIPDomainMapping, dSIPMultiDomainMapping, Dispatcher, Gateways, Subscribers, Leases
from shared import *
import  urllib.parse as parse
import json
import settings

db = loadSession()
api = Blueprint('api', __name__)

@api.route("/api/v1/kamailio/stats", methods=['GET'])
@api_security
def getKamailioStats():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        payload = {"jsonrpc": "2.0", "method": "tm.stats","id": 1}
        #r = requests.get('https://www.google.com',data=payload)
        r = requests.get('http://127.0.0.1:5060/api/kamailio',json=payload)
        #print(r.text)

        return r.text

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()


@api.route("/api/v1/endpoint/lease", methods=['GET'])
@api_security
def getEndpointLease():
    try:
        if (settings.DEBUG):
            debugEndpoint()
        
        email=request.args.get('email')
        if not email:
            raise Exception("email parameter is missing")
        
        ttl=request.args.get('ttl')
        if not ttl:
            raise Exception("time to live (ttl) parameter is missing")

        # Generate some values
        rand_num= random.randint(1,200)
        name = "lease" + str(rand_num)
        auth_username = name
        auth_password = generatePassword()  
        auth_domain = settings.DOMAIN
        if settings.DSIP_API_HOST:
            api_hostname = settings.DSIP_API_HOST
        else:
            api_hostname = getExternalIP()

        #Set some defaults
        ip_addr =''
        strip=''
        prefix=''
        
        #Add the gateway

        Gateway = Gateways(name, ip_addr, strip, prefix, settings.FLT_PBX)
        db.add(Gateway)
        db.flush()

        #Add the subscriber

        Subscriber = Subscribers(auth_username, auth_password, auth_domain, Gateway.gwid)
        db.add(Subscriber)
        db.flush()

        Lease = Leases(Gateway.gwid, Subscriber.id, int(ttl))
        db.add(Lease)
        db.flush()

        payload = {}
        payload['leaseid'] = Lease.id
        payload['username'] = auth_username
        payload['password'] = auth_password
        payload['hostname'] = api_hostname
        payload['domain'] = auth_domain
        payload['ttl'] = ttl

        #Commit transactions to database

        db.commit()
        return json.dumps(payload)

    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "db"
        #db.rollback()
        #db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "http"
        #db.rollback()
        #db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        #db.rollback()
        #db.flush()
        return showError(type=error)
    finally:
        db.close()
