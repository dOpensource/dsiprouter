import sys, os
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from flask import Blueprint, session,render_template, request
from modules.agents.api.routes import agents_api
from modules.agents.db.dsip_agent import Base, dSIPAgent
from sqlalchemy import inspect, text
import settings

agents = agents_api

# Module Metadata
name = "agents"
publisher = "dSIPRouter"
menu_name = "Voice AI Agents"
menu_icon = "glyphicon glyphicon-user"
description = "dSIPRouter Agents Management Module"
version = "1.0.0"
dsip_min_version = "0.78"
agent_image = "dopensource/dsiprouter-voice-agent:latest"

settings.OPENAI_AGENT_IMAGE = agent_image

def init_db(mapper,dbengine):

    Base.metadata.create_all(dbengine)
    inspector = inspect(dbengine)
    if inspector.has_table('dsip_agent'):
        existing_columns = {col['name'] for col in inspector.get_columns('dsip_agent')}
        if 'webhook_secret' not in existing_columns:
            with dbengine.begin() as conn:
                conn.execute(text("ALTER TABLE dsip_agent ADD COLUMN webhook_secret VARCHAR(255) NOT NULL DEFAULT ''"))
        if 'container_port' not in existing_columns:
            with dbengine.begin() as conn:
                conn.execute(text("ALTER TABLE dsip_agent ADD COLUMN container_port VARCHAR(64) NOT NULL DEFAULT ''"))
        if 'container_port_mapped' not in existing_columns:
            with dbengine.begin() as conn:
                conn.execute(text("ALTER TABLE dsip_agent ADD COLUMN container_port_mapped VARCHAR(64) NOT NULL DEFAULT ''"))
        if 'container_port_exposed' in existing_columns:
            with dbengine.begin() as conn:
                conn.execute(text("UPDATE dsip_agent SET container_port_mapped = container_port_exposed WHERE container_port_mapped = ''"))
    #mapper.map_imperatively(dSIPNumber, dsip_number)


def init_module(app, csrf, settings):
    """Initialize the agents module by registering its blueprint."""
    app.register_blueprint(agents) 
    csrf.exempt(agents)

