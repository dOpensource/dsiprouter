import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from flask import Blueprint, render_template, session
from sqlalchemy import exc as sql_exceptions
from werkzeug import exceptions as http_exceptions
from modules.api.licensemanager.classes import WoocommerceError
from modules.api.licensemanager.functions import getLicenseStatus
from modules.api.domains.routes import WRITE_ROLES
from database import startSession, DummySession, Domain
from shared import debugException, debugEndpoint, showError
import settings

domains = Blueprint('domains', __name__)


@domains.route("/domains/msteams/<int:id>", methods=['GET'])
def configureMSTeams(id):
    db = DummySession()

    try:
        if not session.get('logged_in'):
            return render_template('index.html', version=settings.VERSION)

        if (settings.DEBUG):
            debugEndpoint()

        license_status = getLicenseStatus(license_tag='DSIP_MSTEAMS')
        if license_status == 0:
            return render_template('license_required.html', msg=None)

        if license_status == 1:
            return render_template('license_required.html', msg='license is not valid, ensure your license is still active')

        if license_status == 2:
            return render_template('license_required.html', msg='license is associated with another machine, re-associate it with this machine first')

        db = startSession()

        domain_query = db.query(Domain).filter(Domain.id == id)
        domain = domain_query.first()

        return render_template('msteams.html', domainid=id, domain=domain)

    except WoocommerceError as ex:
        return render_template('license_required.html', msg=str(ex))
    except sql_exceptions.SQLAlchemyError as ex:
        debugException(ex)
        error = "db"
        db.rollback()
        db.flush()
        return showError(type=error)
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        error = "http"
        db.rollback()
        db.flush()
        return showError(type=error)
    except Exception as ex:
        debugException(ex, log_ex=True, print_ex=True, showstack=True)
        error = "server"
        db.rollback()
        db.flush()
        return showError(type=error)
    finally:
        db.close()


@domains.route("/domains", methods=['GET'])
def displayDomains():
    try:
        if (settings.DEBUG):
            debugEndpoint()

        if not session.get('logged_in'):
            return render_template('index.html', version=settings.VERSION)

        license_status = getLicenseStatus(license_tag='DSIP_MSTEAMS')
        if license_status == 1:
            return render_template('license_required.html', msg='license is not valid, ensure your license is still active')

        if license_status == 2:
            return render_template('license_required.html', msg='license is associated with another machine, re-associate it with this machine first')

        # the table is loaded from /api/v1/domains, which also enforces the write roles
        user_groups = set(session.get('user_groups', []) or [])
        can_edit = len(user_groups.intersection(WRITE_ROLES)) > 0
        return render_template('domains.html', hc=license_status == 3, can_edit=can_edit)

    except WoocommerceError as ex:
        return render_template('license_required.html', msg=str(ex))
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        return showError(type="http")
    except Exception as ex:
        debugException(ex, log_ex=True, print_ex=True, showstack=True)
        return showError(type="server")
