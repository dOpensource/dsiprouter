from flask import Blueprint,session, render_template
import settings
from modules.domain.domain_service import addDomain,getDomains

domains = Blueprint('domains', __name__)

@domains.route("/domains")
def domainList():
    
    if not session.get('logged_in'):
        return render_template('index.html',version=settings.VERSION)

    res = getDomains()
    return render_template('domains.html', rows=res,version=settings.VERSION)



