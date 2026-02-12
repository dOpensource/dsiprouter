import sys, os
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

from flask import Blueprint, session,render_template, request
from modules.numbers.db.dsip_number import dSIPNumber
from database import startSession, DummySession
from modules.api.api_functions import createApiResponse, showApiError, api_security
from shared import getRequestData, rowToDict, showError, debugException, debugEndpoint
from sqlalchemy import or_
from werkzeug import exceptions as http_exceptions
import settings
import csv
import io

numbers_api = Blueprint('numbers', __name__, template_folder='../templates', static_folder='../static', static_url_path='/numbers/static')

@numbers_api.route('/gui/numbers', methods=['GET'])
def numbers_index():
   
    try:
        if (settings.DEBUG):
            debugEndpoint()

        if not session.get('logged_in'):
            return render_template('index.html', version=settings.VERSION)
        else:
            action = request.args.get('action')
            return render_template('numbers.html', show_add_onload=action, version=settings.VERSION)
            
    except http_exceptions.HTTPException as ex:
        debugException(ex)
        return showError(type='http', code=ex.code, msg=ex.description)
    except Exception as ex:
        debugException(ex, log_ex=False, print_ex=True, showstack=False)
        error = "server"
        return showError(type=error)


@numbers_api.route('/api/numbers/v1/number', methods=['GET'])
@api_security
def get_numbers():
    """Get list of numbers. Supports query params: source, starts_with, contains, ends_with, status."""
    db = DummySession()
    try:
        db = startSession()

        source = None
        starts_with = None
        contains = None
        ends_with = None
        status = None

        # extract from query string
        payload = getRequestData()
        pool= payload['pool'] if 'pool' in payload else None
        source = payload['source'] if 'source' in payload else None
        starts_with = ''.join(payload['starts_with']) if 'starts_with' in payload else None
        contains = ''.join(payload['contains']) if 'contains' in payload else None
        ends_with = ''.join(payload['ends_with']) if 'ends_with' in payload else None
        status = payload['status'] if 'status' in payload else None

        q = db.query(dSIPNumber)

        if source:
            # support using source as either carrier or pool
            q = q.filter(dSIPNumber.carrier == source)

        if starts_with:
            #q = q.filter(dSIPNumber.did.like(f"{starts_with}%"))
            q = q.filter(dSIPNumber.did.like(f"{starts_with}%"))
        if contains:
            q = q.filter(dSIPNumber.did.like(f"%{contains}%"))
        if ends_with:
            q = q.filter(dSIPNumber.did.like(f"%{ends_with}"))
        if status is not None and status != '':
            q = q.filter(dSIPNumber.status == status)
        if pool:
            q = q.filter(dSIPNumber.pool == pool)

        results = q.all()
        data = [rowToDict(r) for r in results]
        count = len(data)

        return createApiResponse(msg=str(count) + ' Numbers Retrieved', data=data)

    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@numbers_api.route('/api/numbers/v1/number', methods=['POST'])
@api_security
def create_number():
    db = DummySession()
    try:
        db = startSession()
        payload = getRequestData()
        did = payload.get('did')
        if not did:
            raise http_exceptions.BadRequest('did is required')

        # CHeck if DID exists
        existing = db.query(dSIPNumber).filter(
            or_(
                dSIPNumber.did == did,
                dSIPNumber.did == "+" + did,
            )).first()
        
        if existing is not None:
            raise http_exceptions.Conflict('DID already exists')
        

        number = dSIPNumber(
            did=did,
            status=payload.get('status'),
            carrier=payload.get('carrier'),
            pool=payload.get('pool'),
            assigned_length=payload.get('assigned_length'),
            assigned_reference_id=payload.get('assigned_reference_id'),
           
        )

        # define an assignd_date if the assigned_length is set
        if payload.get('assigned_length'):
            from datetime import datetime
            number.assigned_date = datetime.utcnow()

        db.add(number)
        db.flush()
        db.commit()

        return createApiResponse(msg='Number created', data=[rowToDict(number)])
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@numbers_api.route('/api/numbers/v1/number/<int:number_id>', methods=['PUT'])
@api_security
def update_number(number_id):
    db = DummySession()
    try:
        db = startSession()
        payload = getRequestData()

        number = db.query(dSIPNumber).filter(dSIPNumber.id == number_id).first()
        if number is None:
            raise http_exceptions.NotFound('Number not found')

        # update fields
        for key in ('did', 'status', 'carrier', 'pool', 'assigned_length', 'assigned_reference_id', 'assigned_date'):
            if key in payload:
                setattr(number, key, payload.get(key))
            if key == 'did' and payload.get('did'):
                # Check if DID exists
                existing = db.query(dSIPNumber).filter(
                    or_(
                        dSIPNumber.did == payload.get('did'),
                        dSIPNumber.did == "+" + payload.get('did'),
                    ),
                    dSIPNumber.id != number_id
                ).first()
                
                if existing is not None:
                    raise http_exceptions.Conflict('DID already exists')
                
        
        # define an assignd_date if the assigned_length is set
        if payload.get('assigned_length'):
            from datetime import datetime
            number.assigned_date = datetime.utcnow()

        db.add(number)
        db.flush()
        db.commit()

        return createApiResponse(msg='Number updated', data=[rowToDict(number)])
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@numbers_api.route('/api/numbers/v1/number/<int:number_id>', methods=['DELETE'])
@api_security
def delete_number(number_id):
    db = DummySession()
    try:
        db = startSession()
        number = db.query(dSIPNumber).filter(dSIPNumber.id == number_id).first()
        if number is None:
            raise http_exceptions.NotFound('Number not found')

        db.delete(number)
        db.flush()
        db.commit()

        return createApiResponse(msg='Number deleted', data=[{'id': number_id}])
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@numbers_api.route('/api/numbers/v1/number', methods=['DELETE'])
@api_security
def delete_numbers_by_dids():
    db = DummySession()
    try:
        db = startSession()
        payload = getRequestData()
        did = payload.get('did')
        dids = payload.get('dids', [])
        id = payload.get('id', [])
        if did:
            dids = [did]
        if not dids and not id:
            raise http_exceptions.BadRequest('did or the id of the did is required')

        deleted = []
        # Delete by DIDs
        for d in dids:
            normalized = d.lstrip('+')
            number = db.query(dSIPNumber).filter(
                or_(
                    dSIPNumber.did == normalized,
                    dSIPNumber.did == "+" + normalized,
                )).first()
            
            if number is not None:
                db.delete(number)
                deleted.append({'did': d, 'id': number.id})

        # Delete by IDs
        for entry in id:
            number = db.query(dSIPNumber).filter(dSIPNumber.id == entry).first()
            if number is not None:
                db.delete(number)
                deleted.append({'id': entry, 'did': number.did})   
            
        # If nothing deleted, raise not found    
        if not deleted:
            raise http_exceptions.NotFound('No numbers found to delete')

        db.flush()
        db.commit()

        return createApiResponse(msg=f'{len(deleted)} Numbers deleted', data=deleted)
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()


@numbers_api.route('/api/numbers/v1/number/bulk', methods=['POST'])
@api_security
def bulk_create_numbers():
    db = DummySession()
    try:
        db = startSession()
        file = request.files.get('file')
        if not file:
            raise http_exceptions.BadRequest('CSV file is required')

        # Read CSV
        stream = io.StringIO(file.stream.read().decode("UTF8"), newline=None)
        csv_input = csv.reader(stream)
        header = next(csv_input)  # Skip header

        numbers = []
        for row in csv_input:
            if len(row) < 1:
                continue
            did = row[0].strip()
            status = row[1].strip() if len(row) > 1 else None
            carrier = row[2].strip() if len(row) > 2 else None
            pool = row[3].strip() if len(row) > 3 else None
            assigned_length = row[4].strip() if len(row) > 4 else None
            assigned_reference_id = row[5].strip() if len(row) > 5 else None

            # Check if DID exists
            existing = db.query(dSIPNumber).filter(
                or_(
                    dSIPNumber.did == did,
                    dSIPNumber.did == "+" + did,
                )).first()
            if existing is not None:
                continue  # Skip existing

            number = dSIPNumber(
                did=did,
                status=status,
                carrier=carrier,
                pool=pool,
                assigned_length=assigned_length,
                assigned_reference_id=assigned_reference_id,
            )
            if assigned_length:
                from datetime import datetime
                number.assigned_date = datetime.utcnow()

            db.add(number)
            numbers.append(number)

        db.flush()
        db.commit()

        data = [rowToDict(n) for n in numbers]
        return createApiResponse(msg=f'{len(numbers)} Numbers created', data=data)
    except Exception as ex:
        db.rollback()
        db.flush()
        return showApiError(ex)
    finally:
        db.close()
