import importlib.util, os
from flask import Blueprint, render_template, abort, jsonify
from util.security import api_security
from database import startSession, DummySession, dSIPMultiDomainMapping
from shared import debugEndpoint,StatusCodes, getRequestData
from modules.api.api_functions import showApiError
from werkzeug import exceptions as http_exceptions
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
import settings


# TODO: standardize response payloads using new createApiResponse()
#       marked for implementation in v0.74


class config():

    hostname=''
    port=''
    username=''
    password=''
    dbname=''
    type=''
    auth_type=''
    plugin_type=''
    plugin=None



    def __init__(self,config_id):

        db = DummySession()

        db = startSession()
        try:
            print("The config_id is {}".format(config_id))
            domainMapping = db.query(dSIPMultiDomainMapping).filter(dSIPMultiDomainMapping.pbx_id == config_id).first()
            if domainMapping is None:
                raise Exception("Configuration doesn't exist")
            else:
                print("***In domain mapping***")
                self.hostname=domainMapping.db_host
                #self.port=domainMapping.port if "port" in domainMapping else "5432"
                self.port="5432"
                self.username=domainMapping.db_username
                self.password=domainMapping.db_password
                self.dbname="fusionpbx"

                #response_payload['msg'] = 'Domain Configuration Exists'

                if domainMapping.type == int(dSIPMultiDomainMapping.FLAGS.TYPE_FUSIONPBX.value):
                    self.plugin_type = FLAGS.FUSIONPBX_PLUGIN
                elif domainMapping.type == dSIPMultiDomainMapping.FLAGS.TYPE_FUSIONPBX_CLUSTER.value:
                    self.plugin_type = FLAGS.FUSIONPBX_PLUGIN
                elif domainMapping.type == dSIPMultiDomainMapping.FLAGS.TYPE_FREEPBX.value:
                    self.plugin_type = FLAGS.FREEPBX_PLUGIN;
                    raise Exception("FreePBX Plugin is not supported yet")
                else:
                    raise Exception("PBX plugin for config #{} can not be found".format(config_id))

                # Import plugin

                # Returns the Base directory of this file
                base_dir = os.path.dirname(__file__)

                # Use the Base Dir to specify the location of the plugin required for this domain
                spec = importlib.util.spec_from_file_location("plugin.{}".format(self.plugin_type), "{}/plugin/{}/interface.py".format(base_dir,self.plugin_type))
                self.plugin = importlib.util.module_from_spec(spec)
                if spec.loader.exec_module(self.plugin):
                    print("***Plugin was loaded***")
                return

        except Exception as ex:
            raise ex
        finally:
            db.close()


    def getPlugin(self):
        if self.plugin:
            return self.plugin
        else:
            raise Exception("The plugin could not be loaded")

class FLAGS():

    FUSIONPBX_PLUGIN = "fusion"
    FREEPBX_PLUGIN = "freepbx"


mediaserver = Blueprint('mediaserver','__name__')

@mediaserver.route('/api/v1/mediaserver/domain/',methods=['GET'])
@mediaserver.route('/api/v1/mediaserver/domain/<string:config_id>',methods=['GET'])
@mediaserver.route('/api/v1/mediaserver/domain/<string:config_id>/<string:domain_id>',methods=['GET'])
@api_security
def getDomains(config_id=None,domain_id=None):
    """
    List all of the domains on a PBX\n
    If the PBX only contains a single domain then it will return the hostname or ip address of the system.
    If the PBX is multi-tenant then a list of all domains will be returned

    ===============
    Request Payload
    ===============

    .. code-block:: json


    {}

    ================
    Response Payload
    ================

    .. code-block:: json

        {
            error: <string>,
            msg: <string>,
            kamreload: <bool>,
            data: [
                domains: [
                    {
                    domain_id: <int>,
                    name: <string>,
                    enabled: <string>,
                    description: <string>
                    }
                ]
            ]
        }
    """

    # Determine which plug-in to use
    # Currently we only support FusionPBX
    # Check if Configuration ID exists

    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        if config_id != None:
            config_info = config(config_id)
            plugin = config_info.getPlugin()
            # Create instance of Media Server Class
            if plugin:
                mediaserver = plugin.mediaserver(config_info)
                if mediaserver:
                    domains = plugin.domains(mediaserver)
                    # Use plugin to get list of domains by calling plugin.<pbxtype>.getDomain()
                    domain_list = domains.read(domain_id)
                    response_payload['msg'] = '{} domains were found'.format(len(domain_list))
                    response_payload['data'].append(domain_list)
        else:
            raise Exception("The configuration id must be provided")

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)




@mediaserver.route('/api/v1/mediaserver/domain',methods=['POST'])
@api_security
def postDomains():

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"name": str, "enabled": bool, "description": str, "config_id": int, "cos": str, "settings": dict}

    # ensure requred args are provided
    REQUIRED_ARGS = {'name','config_id'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}


    try:
        if (settings.DEBUG):
            debugEndpoint()


        # get request data
        data = getRequestData()

        # sanity checks
        for k, v in data.items():
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request data argument '{}' not recognized".format(k))
            if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                raise http_exceptions.BadRequest("Request data argument '{}' not valid".format(k))

        for k in REQUIRED_ARGS:
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request argument '{}' is required".format(k))

        config_id = data['config_id']
        cos = data['cos'] if 'cos' in data else None
        domain_settings = data['settings'] if 'settings' in data else None

        # Create instance of Media Server Class
        if config_id != None:
            config_info = config(config_id)
            plugin = config_info.getPlugin()
            # Create instance of Media Server Class
            if plugin:
                mediaserver = plugin.mediaserver(config_info)
                if mediaserver:
                    domains = plugin.domains(mediaserver)
                    domain = domains.create(data)
                    #Generate Close of Service
                    if cos:
                        cos_object = plugin.cos(domain,data)
                        cos_object.create(cos)
                    if domain_settings:
                        cos_object.create("domain_settings")

                    response_payload['data'] = {"domain_id": domain.domain_id}

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)


@mediaserver.route('/api/v1/mediaserver/domain',methods=['PUT'])
@api_security
def putDomains():

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"name": str, "enabled": bool, "description": str, "config_id": int, "domain_id": str}

    # ensure requred args are provided
    REQUIRED_ARGS = {'domain_id','config_id'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}


    try:
        if (settings.DEBUG):
            debugEndpoint()


        # get request data
        data = getRequestData()

        # sanity checks
        for k, v in data.items():
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request data argument '{}' not recognized".format(k))
            if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                raise http_exceptions.BadRequest("Request data argument '{}' not valid".format(k))

        for k in REQUIRED_ARGS:
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request argument '{}' is required".format(k))

        config_id = data['config_id']
        domain_id = data['domain_id']

        # Create instance of Media Server Class
        if config_id != None and domain_id != None:
            config_info = config(config_id)
            plugin = config_info.getPlugin()
            # Create instance of Media Server Class
            if plugin:
                mediaserver = plugin.mediaserver(config_info)
                if mediaserver:
                    domains = plugin.domains(mediaserver)
                    domain_id = domains.update(data)
                    response_payload['msg'] = "Success"

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)


@mediaserver.route('/api/v1/mediaserver/domain',methods=['DELETE'])
@api_security
def deleteDomains():

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"domain_id": str, "config_id": int}

    # ensure requred args are provided
    REQUIRED_ARGS = {'domain_id','config_id'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}


    try:
        if (settings.DEBUG):
            debugEndpoint()


        # get request data
        data = getRequestData()

        # sanity checks
        for k, v in data.items():
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request data argument '{}' not recognized".format(k))
            if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                raise http_exceptions.BadRequest("Request data argument '{}' not valid".format(k))

        for k in REQUIRED_ARGS:
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request argument '{}' is required".format(k))

        config_id = data['config_id']
        domain_id = data['domain_id']

        # Create instance of Media Server Class
        if config_id != None:
            config_info = config(config_id)
            plugin = config_info.getPlugin()
            # Create instance of Media Server Class
            if plugin:
                mediaserver = plugin.mediaserver(config_info)
                if mediaserver:
                    domains = plugin.domains(mediaserver)
                    # Delete the domain
                    if domains.delete(domain_id):
                        response_payload['msg'] = "Success"

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)




@mediaserver.route('/api/v1/mediaserver/extension',methods=['POST'])
@api_security
def postExtensions():

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"domain_id": str, "account_code": str, "extension": str, "password": str, \
                              "outbound_caller_number": str, "outbound_caller_name": str, "vm_enabled": bool, \
                              "vm_password": int, "vm_notify_email": str, "enabled": bool, "call_timeout": int, \
                              "config_id": int}

    # ensure requred args are provided
    REQUIRED_ARGS = {'domain_id','extension','password', 'enabled','config_id'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}


    try:
        if (settings.DEBUG):
            debugEndpoint()


        # get request data
        data = getRequestData()
        print(data)

        # sanity checks
        for k, v in data.items():
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request data argument '{}' not recognized".format(k))
            if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                raise http_exceptions.BadRequest("Request data argument '{}' not valid".format(k))

        for k in REQUIRED_ARGS:
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request argument '{}' is required".format(k))


        # Create instance of Media Server Class
        config_id = data['config_id']
        domain_id = data['domain_id']

        if config_id != None and domain_id != None:
            config_info = config(config_id)
            plugin = config_info.getPlugin()
            # Create instance of Media Server Class
            if plugin:
                mediaserver = plugin.mediaserver(config_info)
                if mediaserver:
                    domains = plugin.domains(mediaserver)
                    domain = domains.read(domain_id)
                    print(domain_id)
                    print(domain[0]['domain_id'])
                    extensions = plugin.extensions(mediaserver,domain[0])
                    ext = plugin.extension()
                    ext.domain_id=data['domain_id']
                    ext.extension=data['extension']
                    ext.password=data['password']
                    ext.enabled=data['enabled']
                    ext.config_id=data['config_id']
                    ext.outbound_caller_number=data['outbound_caller_number']
                    ext.outbound_caller_name=data['outbound_caller_name']
                    ext.vm_enabled=data['vm_enabled']
                    ext.vm_password=data['vm_password']
                    ext.vm_notify_email=data['vm_notify_email']
                    ext.account_code=data['account_code']
                    ext.call_timeout=data['call_timeout']
                    extensions.create(ext)

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)


@mediaserver.route('/api/v1/mediaserver/extension',methods=['PUT'])
@api_security
def putExtensions():

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"domain_id": str, "account_code": str, "extension": str, "password": str, \
                              "outbound_caller_number": str, "outbound_caller_name": str, "vm_enabled": bool, \
                              "vm_password": int, "vm_notify_email": str, "enabled": bool, "call_timeout": int, \
                              "config_id": int}

    # ensure requred args are provided
    REQUIRED_ARGS = {'domain_id','extension','password', 'enabled','config_id'}

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}


    try:
        if (settings.DEBUG):
            debugEndpoint()


        # get request data
        data = getRequestData()
        print(data)

        # sanity checks
        for k, v in data.items():
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request data argument '{}' not recognized".format(k))
            if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                raise http_exceptions.BadRequest("Request data argument '{}' not valid".format(k))

        for k in REQUIRED_ARGS:
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request argument '{}' is required".format(k))


        # Create instance of Media Server Class
        config_id = data['config_id']
        domain_id = data['domain_id']

        if config_id != None and domain_id != None:
            config_info = config(config_id)
            plugin = config_info.getPlugin()
            # Create instance of Media Server Class
            if plugin:
                mediaserver = plugin.mediaserver(config_info)
                if mediaserver:
                    domains = plugin.domains(mediaserver)
                    domain = domains.read(domain_id)
                    print(domain_id)
                    print(domain[0]['domain_id'])
                    extensions = plugin.extensions(mediaserver,domain[0])
                    extensions.update(data)

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)


@mediaserver.route('/api/v1/mediaserver/extension/<string:config_id>/<string:domain_id>',methods=['GET'])
@mediaserver.route('/api/v1/mediaserver/extension/<string:config_id>/<string:domain_id>/<string:extension_id>',methods=['GET'])
@api_security
def getExtensions(config_id=None,domain_id=None,extension_id=None):
    """
    List all of the domains on a PBX\n
    If the PBX only contains a single domain then it will return the hostname or ip address of the system.
    If the PBX is multi-tenant then a list of all domains will be returned

    ===============
    Request Payload
    ===============

    .. code-block:: json


    {}

    ================
    Response Payload
    ================

    .. code-block:: json
    {
         "data": [
        [
            {
                "call_timeout": null,
                "domain_uuid": "51f66016-c2d5-4bd8-8117-29c8fc8ffa17",
                "enabled": "true",
                "extensions_id": "ae3cb4b8-f467-4a13-9bb8-9296226c1887",
                "number": "504",
                "user_context": "restaurant.detroitpbx.com"
            }
        ]
    }
    """

    # Determine which plug-in to use
    # Currently we only support FusionPBX
    # Check if Configuration ID exists

    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}

    try:
        if settings.DEBUG:
            debugEndpoint()

        if config_id != None and domain_id != None:
            config_info = config(config_id)
            plugin = config_info.getPlugin()
            # Create instance of Media Server Class
            if plugin:
                mediaserver = plugin.mediaserver(config_info)
                if mediaserver:
                    domains = plugin.domains(mediaserver)
                    domain = domains.read(domain_id)
                    extensions = plugin.extensions(mediaserver,domain[0])
                    extension_list = extensions.read(extension_id)
                    response_payload['msg'] = '{} extensions were found'.format(len(extension_list))
                    response_payload['data'].append(extension_list)
        else:
                raise Exception("The configuration id and the domain_id must be provided")

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)


@mediaserver.route('/api/v1/mediaserver/extension',methods=['DELETE'])
@api_security
def deleteExtensions():

    # use a whitelist to avoid possible buffer overflow vulns or crashes
    VALID_REQUEST_DATA_ARGS = {"domain_id": str, "config_id": int, "extension": str}

    # ensure requred args are provided
    REQUIRED_ARGS = VALID_REQUEST_DATA_ARGS

    # defaults.. keep data returned separate from returned metadata
    response_payload = {'error': '', 'msg': '', 'kamreload': getSharedMemoryDict(STATE_SHMEM_NAME)['kam_reload_required'], 'data': []}


    try:
        if (settings.DEBUG):
            debugEndpoint()


        # get request data
        data = getRequestData()

        # sanity checks
        for k, v in data.items():
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request data argument '{}' not recognized".format(k))
            if not type(v) == VALID_REQUEST_DATA_ARGS[k]:
                raise http_exceptions.BadRequest("Request data argument '{}' not valid".format(k))

        for k in REQUIRED_ARGS:
            if k not in VALID_REQUEST_DATA_ARGS.keys():
                raise http_exceptions.BadRequest("Request argument '{}' is required".format(k))

        config_id = data['config_id']
        domain_id = data['domain_id']
        extension = data['extension']

        # Create instance of Media Server Class
        if config_id != None:
            config_info = config(config_id)
            plugin = config_info.getPlugin()
            # Create instance of Media Server Class
            if plugin:
                mediaserver = plugin.mediaserver(config_info)
                if mediaserver:
                    domains = plugin.domains(mediaserver)
                    domain = domains.read(domain_id)
                    if domain:
                        extensions = plugin.extensions(mediaserver,domain[0])
                        if extensions.delete(extension):
                            response_payload['msg'] = "Success"

        return jsonify(response_payload), StatusCodes.HTTP_OK

    except Exception as ex:
        return showApiError(ex)
