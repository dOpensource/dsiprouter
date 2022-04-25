import os, time, json, random, subprocess, requests, csv, base64, codecs, re, OpenSSL
from shared import IO
import settings
from util.security import AES_CTR, urandomChars, EasyCrypto, api_security
from werkzeug import exceptions as http_exceptions
import sys
sys.path.insert(0, '/etc/dsiprouter/gui')

def validateLicense(license_key):
    
    #License Server Host Info
    license_server_base_url = "https://dopensource.com/wp-json/lmfwc/v2/licenses/" 
    license_server_key = "ck_068f510a518ff5ecf1cbdcbc7db7f9bac2331613"
    license_server_secret = "cs_5ae2f3decfa59f427a59b41f2e41459d18023dd7"

    license_info = {}
    license_info["license_valid"] = False
    license_info["license_msg"] = None

    try:
        action = "validate"
        r = requests.get(license_server_base_url + action + "/" + license_key, auth=(license_server_key, license_server_secret))
        
        data = r.json() 
        if data['success'] == True or data['success'] == "true":
            license_info['license_valid'] = True
        else:
            license_info['license_valid'] = False
                
        return license_info
    except Exception as ex:
        msg = r.json()['message']
        ex = http_exceptions.HTTPException(msg)
        ex.code = r.status_code
        if r.status_code == 404:
            license_info['license_msg'] = msg
            return license_info
        else:
            raise ex
