from email.mime import image
import sys, os

import requests
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')


from flask import Blueprint, jsonify, request, Response, session
from database import startSession, DummySession
from modules.api.api_functions import createApiResponse, showApiError, api_security
from shared import getRequestData, rowToDict
from modules.agents.db.dsip_agent import dSIPAgent as dSIPAgent
from modules.agents.db.dsip_agent import dSIPAgentInstruction as dSIPAgentInstruction
from sqlalchemy import exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from flask import render_template
from util.containers import dockerContainer, normalize_container_name
import settings

# Setup some reusable variables and functions for the module
# Set OPENAI_BASE_URL from settings or use default
OPENAI_BASE_URL = settings.OPENAI_BASE_URL if hasattr(settings, 'OPENAI_BASE_URL') else 'https://api.openai.com/v1'

agents_api = numbers_api = Blueprint('agents', __name__, template_folder='../templates', static_folder='../static', static_url_path='/agents/static')


def _infer_container_port(container):
    if not container:
        return ''

    def _normalize_port(value):
        if value is None:
            return ''
        return str(value).split('/')[0]

    target_container_port = '9000/tcp'

    # Refresh docker attrs so port bindings reflect the running container.
    try:
        container.reload()
    except Exception:
        pass

    attrs = getattr(container, 'attrs', None) or {}
    if isinstance(attrs, dict):
        ports = attrs.get('NetworkSettings', {}).get('Ports', {}) or {}
        if target_container_port in ports:
            bindings = ports.get(target_container_port) or []
            if bindings and isinstance(bindings, list):
                host_port = bindings[0].get('HostPort') or ''
                if host_port:
                    return _normalize_port(host_port)

        if ports:
            # Fallback: return first mapped host port if 9000/tcp is unavailable.
            for _container_port, bindings in ports.items():
                if bindings and isinstance(bindings, list):
                    host_port = bindings[0].get('HostPort') or ''
                    if host_port:
                        return _normalize_port(host_port)

    ports = getattr(container, 'ports', None) or {}
    if isinstance(ports, dict) and ports:
        if target_container_port in ports:
            bindings = ports.get(target_container_port) or []
            if bindings and isinstance(bindings, list):
                host_port = bindings[0].get('HostPort') or ''
                if host_port:
                    return _normalize_port(host_port)
        for _container_port, bindings in ports.items():
            if bindings and isinstance(bindings, list):
                host_port = bindings[0].get('HostPort') or ''
                if host_port:
                    return _normalize_port(host_port)

    return ''


class VoiceAgentContainer(dockerContainer):
    def __init__(self, agent_name, image_name=None,container_name=None, agent_instructions=None, agent_api_key=None, webhook_secret=None, tools_api_keys=None, callback_email=None, greeting_message=None):
        self.agent_name = agent_name
        self.image_name = image_name or settings.VOICEAI_AGENT_IMAGE
        self.container_name = container_name
        self.agent_instructions = agent_instructions
        self.agent_api_key = agent_api_key
        self.webhook_secret = webhook_secret
        self.container_port = ''
        self.container_port_mapped = ''
        self.tools_api_keys = tools_api_keys
        self.callback_email = callback_email
        self.greeting_message = greeting_message

        env = {
            'AGENT_NAME': self.agent_name, 
            'AGENT_INSTRUCTIONS': self.agent_instructions or '',
            'AGENT_API_KEY': self.agent_api_key or '',
            'OPENAI_API_KEY': settings.VOICEAI_OPENAI_KEY if hasattr(settings, 'VOICEAI_OPENAI_KEY') else '',
            'WEBHOOK_SECRET': self.webhook_secret or '',
            'OPENAI_WEBHOOK_SECRET': self.webhook_secret or '',
            'TOOLS_API_KEYS': self.tools_api_keys or '',
            'CALLBACK_EMAIL': self.callback_email or '',
            'GREETING_MESSAGE': self.greeting_message or ''
            }

        # Let Docker auto-assign an available host port for container port 9000/tcp.
        dockerContainer.__init__(
            self,
            image_name=self.image_name,
            container_name=container_name or normalize_container_name(self.agent_name),
            environment_vars=env,
            ports={'9000/tcp': ('127.0.0.1', None)}
        )


    def to_dict(self):
        return {
            'agent_name': self.agent_name,
            'image_name' : self.image_name,
            'agent_instructions': self.agent_instructions,
            'agent_api_key': self.agent_api_key,
            'webhook_secret': self.webhook_secret,
            'tools_api_keys': self.tools_api_keys,
            'callback_email': self.callback_email,
            'greeting_message': self.greeting_message
        }
    
    def start(self):
        print(f"Starting agent: {self.agent_name}")
        try:
            container = super().start()
            self.container_port = _infer_container_port(container)
            self.container_port_mapped = self.container_port
            return container is not None
        except Exception as e:
            print(f"Error starting agent {self.agent_name}: {e}")
            return False
        
    
    def restart(self):
        # Placeholder for restarting the agent
        print(f"Restarting agent: {self.agent_name}")
        # Here you would add the logic to gracefully restart the agent, which may involve stopping it first and then starting it again
    
    def stop(self):
        # Placeholder for stopping the agent
        print(f"Stopping agent: {self.agent_name}")
        try:
            super().stop()
            
            return True
        except Exception as e:
            print(f"Error stopping agent {self.agent_name}: {e}")
            return False
        # Here you would add the logic to gracefully stop the agent and clean up resources   

    





def _map_payload_to_agent(payload):
    # Map incoming payload keys to dSIPAgent attributes
    mapped = {}
    mapped['name'] = payload.get('agent-name', payload.get('name', ''))
    mapped['type'] = payload.get('agent-type', payload.get('type', ''))
    mapped['project_id'] = payload.get('agent-project-id', payload.get('project_id', ''))
    mapped['greeting_message'] = payload.get('agent-greeting-message', payload.get('greeting_message', ''))
    mapped['instructions'] = payload.get('agent-instructions', payload.get('instructions', ''))
    mapped['instructions_id'] = payload.get('agent-instructions-id', payload.get('agent-instructions-id', payload.get('instructions_id', 0))) or 0
    mapped['guardrails'] = payload.get('agent-guardrails', payload.get('guardrails', ''))
    mapped['tools'] = payload.get('agent-tools', payload.get('tools', ''))
    mapped['training_website'] = payload.get('agent-training-website', payload.get('training_website', ''))
    mapped['callback_email'] = payload.get('agent-callback-email', payload.get('callback_email', ''))
    mapped['webhook_secret'] = payload.get('agent-webhook-secret', payload.get('webhook_secret', ''))
    mapped['did_mapping'] = payload.get('agent-did-mapping', payload.get('did_mapping', payload.get('did_mappings', '')))
    mapped['deployment_type'] = payload.get('agent-deployment-type', payload.get('deployment_type', ''))
    mapped['deployment_profile_id'] = payload.get('agent-deployment-profile-id', payload.get('deployment_profile_id', 0)) or 0
    return mapped


def _map_payload_to_instruction(payload):
    # Map incoming payload keys to dSIPAgentInstruction attributes
    mapped = {}
    mapped['name'] = payload.get('instruction-name', payload.get('name', ''))
    mapped['project_type'] = payload.get('instruction-project-type', payload.get('project_type', 'openai')) or 'openai'
    mapped['instructions'] = payload.get('instruction-text', payload.get('instructions', ''))
    return mapped


@agents_api.route('/webhook/agents/<string:agent_name>', methods=['POST'])
def proxy_agent_webhook(agent_name):
    db = DummySession()
    try:
        db = startSession()
        agent = db.query(dSIPAgent).filter(dSIPAgent.name == agent_name).first()
        if agent is None:
            raise http_exceptions.NotFound('Agent not found')

        container_port = getattr(agent, 'container_port_mapped', '') or ''
        if not container_port:
            raise http_exceptions.ServiceUnavailable('Agent container port not available')

        remote_uri = f'http://127.0.0.1:{container_port}/'
        proxy_headers = {
            key: value
            for key, value in request.headers.items()
            if key.lower() not in {
                'host',
                'content-length',
                'connection',
                'upgrade',
                'proxy-connection',
            }
        }
        proxy_headers['X-Forwarded-For'] = request.headers.get('X-Forwarded-For', request.remote_addr or '')
        proxy_headers['X-Forwarded-Host'] = request.host
        proxy_headers['X-Forwarded-Proto'] = request.scheme

        upstream_response = requests.post(
            remote_uri,
            headers=proxy_headers,
            data=request.get_data(),
            timeout=15,
        )

        response_headers = {}
        for key, value in upstream_response.headers.items():
            if key.lower() not in {'content-length', 'connection', 'transfer-encoding', 'content-encoding'}:
                response_headers[key] = value

        return Response(
            upstream_response.content,
            status=upstream_response.status_code,
            headers=response_headers,
            content_type=upstream_response.headers.get('Content-Type', 'application/json'),
        )
    except Exception as ex:
        return showApiError(ex)
    finally:
        db.close()


@agents_api.route('/gui/agents', methods=['GET'])
def get_agents_page():
    if not session.get('logged_in'):
        return render_template('index.html', version=settings.VERSION)

    return render_template('agents.html')

@agents_api.route('/api/agents/v1/agent', methods=['GET'])
@agents_api.route('/api/agents/v1/agent/<int:agent_id>', methods=['GET'])
@api_security
def get_agent(agent_id=None):
    db = DummySession()
    try:
        db = startSession()
        if agent_id is None:
            # list all
            agents = db.query(dSIPAgent).all()
            data = [rowToDict(a) for a in agents]
            return createApiResponse(msg='Agents retrieved', data=data)
        else:
            agent = db.query(dSIPAgent).filter(dSIPAgent.id == agent_id).first()
            if agent is None:
                raise http_exceptions.NotFound('Agent not found')
            return createApiResponse(msg='Agent retrieved', data=[rowToDict(agent)])
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@agents_api.route('/api/agents/v1', methods=['POST'])
@agents_api.route('/api/agents/v1/agent', methods=['POST'])
@api_security
def create_agent():
    db = DummySession()
    try:
        db = startSession()
        payload = getRequestData()
        mapped = _map_payload_to_agent(payload)
        print(f'Mapped payload for agent creation: {mapped}')

        agent = dSIPAgent(
            name=mapped['name'],
            type=mapped['type'],
            project_id=mapped['project_id'],
            greeting_message=mapped['greeting_message'],
            instructions=mapped['instructions'],
            instructions_id=int(mapped.get('instructions_id', 0)),
            guardrails=mapped.get('guardrails', ''),
            training_website=mapped.get('training_website', ''),
            tools=mapped.get('tools', ''),
            callback_email=mapped.get('callback_email', ''),
            webhook_secret=mapped.get('webhook_secret', ''),
            did_mapping=mapped.get('did_mapping', ''),
            deployment_type=mapped.get('deployment_type', ''),
            deployment_profile_id=int(mapped.get('deployment_profile_id', 0)),
            image_name=mapped.get('image_name', settings.VOICEAI_AGENT_IMAGE) if 'image_name' in mapped else settings.VOICEAI_AGENT_IMAGE
        )

        db.add(agent)
        db.flush()
        db.commit()

        return createApiResponse(msg='Agent created', data=[rowToDict(agent)])
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@agents_api.route('/api/agents/v1/agent/<int:agent_id>', methods=['PUT'])
@api_security
def update_agent(agent_id):
    db = DummySession()
    try:
        db = startSession()
        payload = getRequestData()
        mapped = _map_payload_to_agent(payload)

        agent = db.query(dSIPAgent).filter(dSIPAgent.id == agent_id).first()
        if agent is None:
            raise http_exceptions.NotFound('Agent not found')

        # update fields
        for k, v in mapped.items():
            # map keys to attribute names on the model
            if hasattr(agent, k):
                setattr(agent, k, v)

        db.add(agent)
        db.flush()
        db.commit()

        return createApiResponse(msg='Agent updated', data=[rowToDict(agent)])
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@agents_api.route('/api/agents/v1/agent/<int:agent_id>/<string:control>', methods=['PUT'])
@api_security
def control_agent(agent_id, control):
    db = DummySession()
    try:
        db = startSession()
        payload = getRequestData()
        mapped = _map_payload_to_agent(payload)

        agent = db.query(dSIPAgent).filter(dSIPAgent.id == agent_id).first()
        if agent is None:
            raise http_exceptions.NotFound('Agent not found')

        # update fields
        #for k, v in mapped.items():
        #    # map keys to attribute names on the model
        #    if hasattr(agent, k):
        #        setattr(agent, k, v)

        # Handle control actions
        if control == 'start':
            # Placeholder for starting the agent
            print(f"Starting agent: {agent.name}")
            va = VoiceAgentContainer(agent_name=agent.name, container_name=agent.container_name, image_name=agent.image_name, agent_instructions=agent.instructions, tools_api_keys=agent.tools, callback_email=agent.callback_email, greeting_message=agent.greeting_message,webhook_secret=agent.webhook_secret)
            if va.start():
                agent.status = 1
                agent.container_port = getattr(va, 'container_port', '')
                agent.container_port_mapped = getattr(va, 'container_port_mapped', '')
                db.add(agent)
                db.flush()
                db.commit()
            # Here you would add the logic to initialize and start the agent based on its configuration   
        elif control == 'stop':
            # Placeholder for stopping the agent
            print(f"Stopping agent: {agent.name}")
            va = VoiceAgentContainer(agent_name=agent.name, container_name=agent.container_name, image_name=agent.image_name, agent_instructions=agent.instructions, tools_api_keys=agent.tools, callback_email=agent.callback_email, greeting_message=agent.greeting_message)
            if va.stop():
                agent.status = 0
                agent.container_port = ''
                agent.container_port_mapped = ''
                db.add(agent)
                db.flush()
                db.commit()
        elif control == 'restart':
            # Placeholder for restarting the agent
            print(f"Restarting agent: {agent.name}")
            va = VoiceAgentContainer(agent_name=agent.name, container_name=agent.container_name, image_name=agent.image_name, agent_instructions=agent.instructions, tools_api_keys=agent.tools, callback_email=agent.callback_email, greeting_message=agent.greeting_message).restart(agent.name) 
            if va.restart():
                agent.status = 1
                db.add(agent)
                db.flush()
                db.commit()
            # Here you would add the logic to gracefully restart the agent, which may involve stopping it first and then starting it again
        else:
            raise http_exceptions.BadRequest('Invalid control action')  
             

        db.add(agent)
        db.flush()
        db.commit()

        return createApiResponse(msg='Agent Started', data="")
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@agents_api.route('/api/agents/v1/agent/<int:agent_id>', methods=['DELETE'])
@api_security
def delete_agent(agent_id):
    db = DummySession()
    try:
        db = startSession()

        agent = db.query(dSIPAgent).filter(dSIPAgent.id == agent_id).first()
        if agent is None:
            raise http_exceptions.NotFound('Agent not found')

        db.delete(agent)
        db.flush()
        db.commit()

        return createApiResponse(msg='Agent deleted', data=[{'id': agent_id}])
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@agents_api.route('/api/agents/v1/instructions', methods=['GET'])
@agents_api.route('/api/agents/v1/instructions/<int:instruction_id>', methods=['GET'])
@api_security
def get_agent_instructions(instruction_id=None):
    db = DummySession()
    try:
        db = startSession()
        if instruction_id is None:
            instructions = db.query(dSIPAgentInstruction).all()
            data = [rowToDict(instruction) for instruction in instructions]
            return createApiResponse(msg='Instructions retrieved', data=data)

        instruction = db.query(dSIPAgentInstruction).filter(dSIPAgentInstruction.id == instruction_id).first()
        if instruction is None:
            raise http_exceptions.NotFound('Instruction not found')

        return createApiResponse(msg='Instruction retrieved', data=[rowToDict(instruction)])
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@agents_api.route('/api/agents/v1/instructions', methods=['POST'])
@api_security
def create_agent_instruction():
    db = DummySession()
    try:
        db = startSession()
        payload = getRequestData()
        mapped = _map_payload_to_instruction(payload)

        instruction = dSIPAgentInstruction(
            name=mapped['name'],
            project_type=mapped['project_type'],
            instructions=mapped['instructions'],
        )

        db.add(instruction)
        db.flush()
        db.commit()

        return createApiResponse(msg='Instruction created', data=[rowToDict(instruction)])
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@agents_api.route('/api/agents/v1/instructions/<int:instruction_id>', methods=['PUT'])
@api_security
def update_agent_instruction(instruction_id):
    db = DummySession()
    try:
        db = startSession()
        payload = getRequestData()
        mapped = _map_payload_to_instruction(payload)

        instruction = db.query(dSIPAgentInstruction).filter(dSIPAgentInstruction.id == instruction_id).first()
        if instruction is None:
            raise http_exceptions.NotFound('Instruction not found')

        for k, v in mapped.items():
            if hasattr(instruction, k):
                setattr(instruction, k, v)

        db.add(instruction)
        db.flush()
        db.commit()

        return createApiResponse(msg='Instruction updated', data=[rowToDict(instruction)])
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@agents_api.route('/api/agents/v1/instructions/<int:instruction_id>', methods=['DELETE'])
@api_security
def delete_agent_instruction(instruction_id):
    db = DummySession()
    try:
        db = startSession()

        instruction = db.query(dSIPAgentInstruction).filter(dSIPAgentInstruction.id == instruction_id).first()
        if instruction is None:
            raise http_exceptions.NotFound('Instruction not found')

        db.delete(instruction)
        db.flush()
        db.commit()

        return createApiResponse(msg='Instruction deleted', data=[{'id': instruction_id}])
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@agents_api.route('/api/agents/v1/projects/<string:provider>', methods=['GET'])
@api_security
def get_projects_by_provider(provider):
    db = DummySession()

    if provider.lower() != 'openai':
        return showApiError(f'Provider {provider} not supported', code=400) 
    try:
        headers = {'Authorization': f'Bearer {settings.VOICEAI_OPENAI_KEY}'
                   , 'Content-Type': 'application/json'}
       
        print(headers)
        r = requests.get(f'{OPENAI_BASE_URL}/organization/projects', headers=headers)
        if r.status_code != 200:
            raise http_exceptions.InternalServerError(f'Failed to retrieve projects from provider: {provider}. \
                 HTTP Return Status Code {r.status_code}: {r.reason}')
        projects = r.json().get('data', [])
        return createApiResponse(msg='Projects retrieved', data=projects)
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()

