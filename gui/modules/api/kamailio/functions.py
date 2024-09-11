import requests, sys
from time import sleep, time
from typing import Union
from werkzeug import exceptions as http_exceptions

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from shared import IO
from util.security import AES_CTR
from modules.api.kamailio.errors import NoDispatcherSets, KamailioError
import settings


def sendJsonRpcCmd(host, method, params=(), timeout=settings.KAM_JSONRPC_TIMEOUT):
    """
    Send a JSONRPC command to Kamailio

    :param host:      the host to send the request to
    :type host:       str
    :param method:    method as parsed by `kamcmd <https://github.com/kamailio/kamailio/tree/master/utils/kamcmd>`_
    :type method:     str
    :param params:    parameters for the command
    :type params:     tuple|list
    :param timeout:   timeout in seconds for command to finish
    :type timeout:    int
    :return:          The result from Kamailio
    :rtype:           dict
    :raises requests.exceptions.HTTPError:          if an HTTP error occurred
    :raises requests.exceptions.JSONDecodeError:    if a JSON parsing error occurred
    :raises KamailioError:                          if communicating with Kamailio failed
    :raises Exception:                              for any other error
    """

    if settings.DEBUG:
        IO.printdbg(f'sending jsonrpc command to {host}: {method} {str(params)}')

    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json"
    }
    payload = {
        "method": method,
        "jsonrpc": settings.KAM_JSONRPC_VERSION,
        "id": settings.KAM_JSONRPC_ID
    }
    if len(params) > 0:
        payload['params'] = params

    def sendit(host):
        return requests.post(
            f'http://{host}:5060{settings.KAM_JSONRPC_ROOTPATH}',
            headers=headers,
            json=payload,
            timeout=timeout,
        )

    r: Union[requests.Response, None] = None
    cutoff_time = time() + timeout
    while time() < cutoff_time:
        try:
            r = sendit(host)
            r.raise_for_status()
            break
        except requests.exceptions.HTTPError as ex:
            if ex.response.status_code == 500 and ex.response.json()['error']['message'] == 'ongoing reload':
                sleep(settings.KAM_JSONRPC_RETRYIVAL)
                continue
            raise

    data = r.json()
    if "error" in data:
        # specific cases
        if data["error"] == "No Destination Sets":
            raise NoDispatcherSets(data["error"])
        # general case
        raise KamailioError(data["error"])

    return data['result']


def reloadKamailio():
    try:
        # format some settings for kam config
        dsip_api_url = settings.DSIP_API_PROTO + '://' + '127.0.0.1' + ':' + str(settings.DSIP_API_PORT)
        if isinstance(settings.DSIP_API_TOKEN, bytes):
            dsip_api_token = AES_CTR.decrypt(settings.DSIP_API_TOKEN)
        else:
            dsip_api_token = settings.DSIP_API_TOKEN

        # data that is always reloaded, part of core dsiprouter
        rpc_args = [
            ('127.0.0.1', 'cfg.sets', ['server', 'role', settings.ROLE]),
            ('127.0.0.1', 'cfg.sets', ['server', 'api_server', dsip_api_url]),
            ('127.0.0.1', 'cfg.sets', ['server', 'api_token', dsip_api_token]),
            ('127.0.0.1', 'htable.reload', ['maintmode']),
            ('127.0.0.1', 'htable.reload', ['gw2gwgroup']),
            ('127.0.0.1', 'htable.reload', ['gwgroup2lb']),
            ('127.0.0.1', 'htable.reload', ['inbound_hardfwd']),
            ('127.0.0.1', 'htable.reload', ['inbound_failfwd']),
            ('127.0.0.1', 'htable.reload', ['prefix_to_route']),
        ]

        # reload data depending on the features enabled
        features_enabled = {
            x['name'] for x in sendJsonRpcCmd('127.0.0.1', 'core.ppdefines_full') \
            if x['value'] == 'none'
        }
        if 'WITH_AUTH' in features_enabled and 'WITH_IPAUTH' in features_enabled:
            rpc_args.append(('127.0.0.1', 'permissions.addressReload'))
        if 'WITH_UAC' in features_enabled:
            rpc_args.append(('127.0.0.1', 'uac.reg_reload'))
        if 'WITH_DROUTE' in features_enabled:
            rpc_args.append(('127.0.0.1', 'drouting.reload'))
        if 'WITH_DISPATCHER' in features_enabled:
            rpc_args.append(('127.0.0.1', 'dispatcher.reload'))
            rpc_args.append(('127.0.0.1', 'keepalive.flush'))
        if 'WITH_CALL_SETTINGS' in features_enabled:
            rpc_args.append(('127.0.0.1', 'htable.reload', ['call_settings']))
        if 'WITH_MULTIDOMAIN' in features_enabled:
            rpc_args.append(('127.0.0.1', 'domain.reload'))
        if 'WITH_TELEBLOCK' in features_enabled:
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['teleblock', 'gw_enabled', str(settings.TELEBLOCK_GW_ENABLED)]))
        if 'WITH_LCR' in features_enabled:
            rpc_args.append(('127.0.0.1', 'htable.reload', ['tofromprefix']))
        #if 'WITH_TLS' in features_enabled:
        #    # TODO: tls.reload is VERY slow on some systems. Commented out until we get a resolution
        #    rpc_args.append(('127.0.0.1', 'tls.reload', [], 20))
        if 'WITH_WEBSOCKETS' in features_enabled:
            rpc_args.append(('127.0.0.1', 'ws.enable'))
        if 'WITH_DNID_LNP_ENRICHMENT' in features_enabled:
            rpc_args.append(('127.0.0.1', 'htable.reload', ['enrichdnid_lnpmap']))
        if 'WITH_RTPENGINE' in features_enabled:
            rpc_args.append(('127.0.0.1', 'rtpengine.enable', ['all', 1]))
        if 'WITH_TRANSNEXUS' in features_enabled:
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['transnexus', 'authservice_enabled', str(settings.TRANSNEXUS_AUTHSERVICE_ENABLED)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['transnexus', 'authservice_host', str(settings.TRANSNEXUS_AUTHSERVICE_HOST)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['transnexus', 'verifyservice_enabled', str(settings.TRANSNEXUS_VERIFYSERVICE_ENABLED)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['transnexus', 'verifyservice_host', str(settings.TRANSNEXUS_VERIFYSERVICE_HOST)]))
        if 'WITH_STIRSHAKEN' in features_enabled:
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['stir_shaken', 'stir_shaken_enabled', str(settings.STIR_SHAKEN_ENABLED)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['stir_shaken', 'stir_shaken_prefix_a', str(settings.STIR_SHAKEN_PREFIX_A)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['stir_shaken', 'stir_shaken_prefix_b', str(settings.STIR_SHAKEN_PREFIX_B)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['stir_shaken', 'stir_shaken_prefix_c', str(settings.STIR_SHAKEN_PREFIX_C)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['stir_shaken', 'stir_shaken_prefix_invalid', str(settings.STIR_SHAKEN_PREFIX_INVALID)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['stir_shaken', 'stir_shaken_block_invalid', str(settings.STIR_SHAKEN_BLOCK_INVALID)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['stir_shaken', 'stir_shaken_key_path', str(settings.STIR_SHAKEN_KEY_PATH)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['stir_shaken', 'stir_shaken_cert_url', str(settings.STIR_SHAKEN_CERT_URL)]))

        # data that is conditionally reloaded based on dsiprouter settings
        if settings.TELEBLOCK_GW_ENABLED:
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['teleblock', 'gw_ip', str(settings.TELEBLOCK_GW_IP)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['teleblock', 'gw_port', str(settings.TELEBLOCK_GW_PORT)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['teleblock', 'media_ip', str(settings.TELEBLOCK_MEDIA_IP)]))
            rpc_args.append(('127.0.0.1', 'cfg.sets', ['teleblock', 'media_port', str(settings.TELEBLOCK_MEDIA_PORT)]))

        # send off all the jsonrpc requests and handle any failures if possible
        for cmdset in rpc_args:
            try:
                sendJsonRpcCmd(*cmdset)
            except NoDispatcherSets:
                pass
            except KamailioError as ex:
                err = http_exceptions.HTTPException(str(ex))
                err.code = 500
                raise err
            except requests.exceptions.HTTPError as ex:
                err = http_exceptions.HTTPException(response=ex.response)
                raise err

        IO.printinfo("[---- Reloaded Kamailio with dSIPRouter Settings ----]")
    except Exception as ex:
        IO.printerr("[---- Could not reload Kamailio with dSIPRouter Settings ----]")
        raise ex
