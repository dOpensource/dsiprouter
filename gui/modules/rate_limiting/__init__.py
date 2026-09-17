import sys, os
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from modules.rate_limiting.api.routes import rate_limiting_api

rate_limiting = rate_limiting_api

# Module Metadata
name = "rate_limiting"
publisher = "dSIPRouter"
menu_name = "Rate Limiting"
menu_icon = "ti ti-shield-lock"
description = "dSIPRouter Rate Limiting Module (Kamailio pike)"
version = "1.0.0"
dsip_min_version = "0.78"


def init_module(app, csrf, settings):
    """Initialize the rate_limiting module by registering its blueprint."""
    app.register_blueprint(rate_limiting)
    csrf.exempt(rate_limiting)
