from flask import Blueprint, render_template, abort
from util.security import api_security


new_api = Blueprint('new_api','__name__')

# Sample route.  Replace new_api and new_entity with the name of the api
# and the name of the entity that it will manipulate
@new_api.route('/api/v1/new_api/new_entity')
@api_security
def getEntity():
    result = "{ \
        domain_id: 1012 \
        name: AprilandMackCo, \
        enabled: true, \
        description: 'April and Mack Co', \
        config_id: 64 \
        }"
    return result;
