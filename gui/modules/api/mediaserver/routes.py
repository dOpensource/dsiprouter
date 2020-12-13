from flask import Blueprint, render_template, abort
from util.security import api_security


mediaserver = Blueprint('mediaserver','__name__')

@mediaserver.route('/api/v1/mediaserver/domain')
@api_security
def getDomains():
    result = "{ \
        domain_id: 1012 \
        name: AprilandMackCo, \
        enabled: true, \
        description: 'April and Mack Co', \
        config_id: 64 \
        }"
    return result;
