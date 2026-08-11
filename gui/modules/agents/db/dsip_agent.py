"""dSIP Agent DB model (MetaData approach)

This module defines the dSIPAgent class which models the `dsip_agent` table.
Column attribute names are Python-safe (underscores) and mapped to the
actual DB column names where those contain hyphens.
"""
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import text
from sqlalchemy.orm import DeclarativeBase  
from util.containers import normalize_container_name
import settings


class Base(DeclarativeBase):
    pass

class dSIPAgent(Base):
    """Model for `dsip_agent` table.

    Columns mirror the SQL schema. For DB column names that contain hyphens
    we use a Python-friendly attribute name and provide the DB column name
    as the first argument to Column(), e.g. Column('project-id', String(...)).
    """
    __tablename__ = 'dsip_agent'
    id = Column(Integer, primary_key=True, autoincrement=True, nullable=False)
    name = Column(String(255), nullable=False)
    # column name is `type` in the DB; using attribute name `type` here
    # is acceptable and follows existing project patterns.
    type = Column('type', String(128), nullable=False)
    project_id = Column('project_id', String(255), nullable=False)
    greeting_message = Column('greeting_message', String(512), nullable=False)
    instructions = Column(String(1024), nullable=False)
    instructions_id = Column('instructions_id', Integer, nullable=False, default=0)
    guardrails = Column(String(255), nullable=False, default='')
    training_website = Column('training_website', String(255), nullable=False, default='')
    tools = Column(String(255), nullable=False, default='')
    callback_email = Column('callback_email', String(255), nullable=False, default='')
    did_mapping = Column('did_mapping', String(255), nullable=False, default='')
    deployment_type = Column('deployment_type', String(255), nullable=False, default='')
    deployment_profile_id = Column('deployment_profile_id', Integer, nullable=False, default=0)
    container_name = Column('container_name', String(255), nullable=False, default='')
    container_port = Column('container_port', String(64), nullable=False, default='')
    container_port_mapped = Column('container_port_mapped', String(64), nullable=False, default='')
    image_name = Column('image_name', String(255), nullable=False, default='')
    created_at = Column('created_at', DateTime,
                        server_default=text('CURRENT_TIMESTAMP'),
                        server_onupdate=text('CURRENT_TIMESTAMP'))
    modified_at = Column('modified_at', DateTime,
                         server_default=text('CURRENT_TIMESTAMP'),
                         server_onupdate=text('CURRENT_TIMESTAMP'))
    status = Column(Integer, nullable=False, default=0)
    error = Column(String(200), nullable=False, default='')
    webhook_secret = Column('webhook_secret', String(255), nullable=False, default='')
    # optional; passed to the container as AGENT_SERVICES_API_KEY
    agent_services_api_key = Column('agent_services_api_key', String(255), nullable=False, default='')

    def __init__(self, name, type, project_id, greeting_message, instructions,
                 instructions_id=0, guardrails='', tools='', callback_email='',
                 training_website='', did_mapping='', deployment_type='', deployment_profile_id=0, status=0, error='', image_name=settings.VOICEAI_AGENT_IMAGE,webhook_secret="", container_port='', container_port_mapped='', agent_services_api_key=''):
        self.name = name
        self.type = type
        self.project_id = project_id
        self.greeting_message = greeting_message
        self.instructions = instructions
        self.instructions_id = instructions_id
        self.guardrails = guardrails
        self.tools = tools
        self.callback_email = callback_email
        self.training_website = training_website
        self.did_mapping = did_mapping
        self.deployment_type = deployment_type
        self.container_name = normalize_container_name(name)
        self.container_port = container_port
        self.container_port_mapped = container_port_mapped
        self.image_name = image_name
        self.deployment_profile_id = deployment_profile_id
        self.status = status
        self.error = error
        self.webhook_secret = webhook_secret
        self.agent_services_api_key = agent_services_api_key

    def to_dict(self):
        """Return a plain dict representation of this object (simple fields)."""
        return {
            'id': getattr(self, 'id', None),
            'name': self.name,
            'type': self.type,
            'project_id': self.project_id,
            'greeting_message': self.greeting_message,
            'instructions': self.instructions,
            'instructions_id': self.instructions_id,
            'guardrails': self.guardrails,
            'tools': self.tools,
            'callback_email': self.callback_email,
            'training_website': self.training_website,
            'did_mapping': self.did_mapping,
            'deployment_type': self.deployment_type,
            'deployment_profile_id': self.deployment_profile_id,
            'container_port': self.container_port,
            'container_port_mapped': self.container_port_mapped,
            'created_at': getattr(self, 'created_at', None),
            'modified_at': getattr(self, 'modified_at', None),
            'status': self.status,
            'error': self.error,
            'image': self.image,
            'webhook_secret': self.webhook_secret,
            'agent_services_api_key': self.agent_services_api_key
        }


class dSIPAgentInstruction(Base):
    """Model for `dsip_agent_instruction` table."""

    __tablename__ = 'dsip_agent_instruction'

    id = Column(Integer, primary_key=True, autoincrement=True, nullable=False)
    name = Column(String(255), nullable=False)
    project_type = Column(String(255), nullable=False, default='openai')
    instructions = Column(String(4096), nullable=False)

    def __init__(self, name, instructions, project_type='openai'):
        self.name = name
        self.project_type = project_type
        self.instructions = instructions

    def to_dict(self):
        """Return a plain dict representation of this object."""
        return {
            'id': getattr(self, 'id', None),
            'name': self.name,
            'project_type': self.project_type,
            'instructions': self.instructions,
        }
