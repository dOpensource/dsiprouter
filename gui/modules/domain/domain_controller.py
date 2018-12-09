from flask import Blueprint,session, render_template
from flask import Flask, render_template, request, redirect, abort, flash, session, url_for, send_from_directory
import settings
from shared import getInternalIP, getExternalIP, updateConfig, getCustomRoutes, debugException, debugEndpoint, \
        stripDictVals
from modules.domain.domain_service import addDomainService,getDomains,deleteDomainService,getPBXLookUp

domains = Blueprint('domains', __name__)

@domains.route("/domains", methods=['GET'])
def domainList():
    

    if not session.get('logged_in'):
        return render_template('index.html',version=settings.VERSION)

    res = getDomains()
    lookup = getPBXLookUp()

    #for x in lookup:
    #    print(lookup[x][0])
    #    print(lookup[x][1])

    return render_template('domains.html', rows=res,pbxlookup=lookup,version=settings.VERSION)



@domains.route("/domains", methods=['POST'])
def addDomain():    
    if not session.get('logged_in'):
        return render_template('index.html',version=settings.VERSION)

    global reload_required

    try:
    
        if (settings.DEBUG):
            debugEndpoint()

        form = stripDictVals(request.form.to_dict())
    
        domainlist = request.form['domainlist']
        authtype = request.form['authtype']
        pbx = request.form['pbx']
        
        domainlist = domainlist.split(",")
        
        for domain in domainlist:
            addDomainService(domain.strip(),authtype,pbx)
        
        reload_required = True 
        return domainList()

    finally:
        reload_required = True

@domains.route("/domainsdelete", methods=['POST'])
def deleteDomain():

    if not session.get('logged_in'):
        return render_template('index.html',version=settings.VERSION)

    global reload_required

    try:
        if (settings.DEBUG):
            debugEndpoint()
        
        form = stripDictVals(request.form.to_dict())

        domainid = request.form['domainid']
        domainname = request.form['domainname']

        deleteDomainService(domainid,domainname)
        reload_required = True 
        return redirect(url_for('domains.domainList'))
        
    finally:
        reload_required = False
    
