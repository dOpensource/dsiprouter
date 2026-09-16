import sys, os
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from modules.security_settings.api.routes import security_settings_api

security_settings = security_settings_api

# Module Metadata
name = "security_settings"
publisher = "dSIPRouter"
menu_name = "Security Settings"
menu_icon = "ti ti-shield-lock"
description = "dSIPRouter Security Settings Module"
version = "1.0.0"
dsip_min_version = "0.78"


def init_module(app, csrf, settings):
    """Initialize the security_settings module by registering its blueprint."""
    app.register_blueprint(security_settings)
    csrf.exempt(security_settings)
