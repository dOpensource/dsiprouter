import os, time, json, random, subprocess, requests, csv, base64, codecs, re, OpenSSL
from shared import IO
import settings
from util.security import AES_CTR, urandomChars, EasyCrypto, api_security
from werkzeug import exceptions as http_exceptions
import sys
sys.path.insert(0, '/etc/dsiprouter/gui')

def reloadKamailio():

    try:

        # format some settings for kam config
        dsip_api_url = settings.DSIP_API_PROTO + '://' + '127.0.0.1' + ':' + str(settings.DSIP_API_PORT)
        if isinstance(settings.DSIP_API_TOKEN, bytes):
            dsip_api_token = AES_CTR.decrypt(settings.DSIP_API_TOKEN).decode('utf-8')
        else:
            dsip_api_token = settings.DSIP_API_TOKEN

        # Pulled tls.reload out of the reload process due to issues
        # {'method': 'tls.reload', 'jsonrpc': '2.0', 'id': 1},


        reload_cmds = [
            {"method": "permissions.addressReload", "jsonrpc": "2.0", "id": 1},
            {'method': 'drouting.reload', 'jsonrpc': '2.0', 'id': 1},
            {'method': 'domain.reload', 'jsonrpc': '2.0', 'id': 1},
            {'method': 'tls.reload', 'jsonrpc': '2.0', 'id': 1},
            {'method': 'dispatcher.reload', 'jsonrpc': '2.0', 'id': 1},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["tofromprefix"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["maintmode"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["calllimit"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["gw2gwgroup"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["inbound_hardfwd"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["inbound_failfwd"]},
            {'method': 'htable.reload', 'jsonrpc': '2.0', 'id': 1, 'params': ["inbound_prefixmap"]},
            {'method': 'uac.reg_reload', 'jsonrpc': '2.0', 'id': 1},
            {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1, 'params': ['teleblock', 'gw_enabled', str(settings.TELEBLOCK_GW_ENABLED)]},
            {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1, 'params': ['server', 'role', settings.ROLE]},
            {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1, 'params': ['server', 'api_server', dsip_api_url]},
            {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1, 'params': ['server', 'api_token', dsip_api_token]}
        ]

        if settings.TELEBLOCK_GW_ENABLED:
            reload_cmds.append(
                {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1,
                 'params': ['teleblock', 'gw_ip', str(settings.TELEBLOCK_GW_IP)]})
            reload_cmds.append(
                {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1,
                 'params': ['teleblock', 'gw_port', str(settings.TELEBLOCK_GW_PORT)]})
            reload_cmds.append(
                {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1,
                 'params': ['teleblock', 'media_ip', str(settings.TELEBLOCK_MEDIA_IP)]})
            reload_cmds.append(
                {'method': 'cfg.seti', 'jsonrpc': '2.0', 'id': 1,
                 'params': ['teleblock', 'media_port', str(settings.TELEBLOCK_MEDIA_PORT)]})

        # Settings for TransNexus 
            reload_cmds.append(
                {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1,
                 'params': ['transnexus', 'authservice_enabled', str(settings.TRANSNEXUS_AUTHSERVICE_ENABLED)]})
            reload_cmds.append(
                {'method': 'cfg.sets', 'jsonrpc': '2.0', 'id': 1,
                 'params': ['transnexus', 'authservice_host', str(settings.TRANSNEXUS_AUTHSERVICE_HOST)]})

        for cmdset in reload_cmds:
            r = requests.get('http://127.0.0.1:5060/api/kamailio', json=cmdset)
            if r.status_code >= 400:
                try:
                    msg = r.json()['error']['message']
                except:
                    msg = r.reason
                ex = http_exceptions.HTTPException(msg)
                ex.code = r.status_code
                raise ex

        IO.printinfo("[---- Reloaded Kamailio with dSIPRouter Settings ----]")    
    except Exception as ex:
        IO.printerr("[---- Could not reload Kamailio with dSIPRouter Settings ----]")  
        raise ex
