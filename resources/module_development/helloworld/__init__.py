import sys, os
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from flask import Blueprint, render_template
from modules.api.api_functions import api_security

name = "helloworld"
menu_name = "Hello World"
version = "1.0.0"
description = "Simple Hello World Module"
dsip_min_version = "0.78"


def init_module(app, csrf, settings):
    helloworld_bp = Blueprint(name, __name__, template_folder='templates', static_folder=name + '/static')
    
    # GUI Route
    @helloworld_bp.route('/gui/' + name, methods=['GET'])
    def helloworld_home():
        return render_template("helloworld.html", message="Welcome to Hello World!")

    # Non-Secure API Route
    @helloworld_bp.route(f"/api/{name}/v1", methods=['GET'])
    def helloworld_api():
        return {"message": "API endpoint for Hello World"}

     # Secure API Route
    @helloworld_bp.route(f"/api/{name}-secure/v1", methods=['GET'])
    @api_security
    def helloworld_secure_api():
        return {"message": "Secure API endpoint for Hello World"}

    app.register_blueprint(helloworld_bp)