from flask import Flask, render_template, request, redirect, abort, flash, session
from flask_script import Manager
import settings
from database import loadSession, Gateways,Address,InboundMapping,OutboundRoutes
import os
import subprocess

app = Flask(__name__, static_folder="./static", static_url_path="/static")
app.debug = settings.DEBUG
#app.add_template_filter()
db = loadSession(); 

@app.route('/')
def index():
    if not session.get('logged_in'):
        return render_template('index.html',version=settings.VERSION)
    else:
        action = request.args.get('action')
        return render_template('dashboard.html',show_add_onload=action, version=settings.VERSION)

@app.route('/login', methods=['POST'])
def login():
    if request.form['password'] == settings.PASSWORD and request.form['username'] == settings.USERNAME:
        session['logged_in'] = True
        session['username'] = request.form['username']
    else:
        flash('wrong password!')
    return index()

@app.route('/logout')
def logout():
    session['logged_in'] = False
    return index()

@app.route('/carriers')
def displayCarriers(db_err=0):
    if session.get('logged_in'):
       try:
           res = db.query(Gateways).filter(Gateways.type==settings.FLT_CARRIER).all()
           return render_template('carriers.html',rows=res)
       except:
           db.rollback()
           if db_err <= 3:
           #Try again
               db_err=db_err+1
               print(db_err)
               return displayCarriers(db_err);
           else:
               return render_template('error.html',type="db")
    else:
       return index()

@app.route('/carriers', methods=['POST'])
def addUpdateCarriers():
    gwid = request.form['gwid']
    name = request.form['name']
    ip_addr = request.form['ip_addr']
    strip = request.form['strip']
    prefix = request.form['prefix']
    # Adding
    if len(gwid) <= 0:
        print(name)
        Gateway = Gateways(name,ip_addr,strip,prefix,settings.FLT_CARRIER)
        Addr=Address(name,ip_addr,32,settings.FLT_PBX)
        
        try:
              db.add(Gateway)
              db.add(Addr)
              db.commit()
              return displayCarriers()
        except:
              db.rollback()
              return render_template('error.html',type="db")
    # Updating
    else:
        db.query(Gateways).filter(Gateways.gwid==gwid).update({'description':"name:"+name,'address':ip_addr,'strip':strip,'pri_prefix':prefix})
        #TODO: You will end up with multiple Address records -will fix
        Addr=Address(name,ip_addr,32,settings.FLT_PBX)
        try:
            db.add(Addr)
            db.commit()
            return displayCarriers()
        except:
             db.rollback()	
             return render_template('error.html',type="db")

@app.route('/carrierdelete',methods=['POST'])
def deleteCarriers():
    gwid = request.form['gwid']
    name = request.form['name']
    d = db.query(Gateways).filter(Gateways.gwid==gwid)
    d.delete(synchronize_session=False)
    a = db.query(Address).filter(Address.tag=='name:'+name)
    a.delete(synchronize_session=False)
    return displayCarriers()

@app.route('/pbx')
def displayPBX(db_err=0):
    if session.get('logged_in'):
       try:
           res = db.query(Gateways).filter(Gateways.type==settings.FLT_PBX).all()
           return render_template('pbxs.html',rows=res)
       except:
           if db_err <= 3:
              db.rollback()
              db_err=db_err + 1
              return displayPBX(db_err)
           else:
              return render_template('error.html',type="db")
    else:
       return index()

@app.route('/pbx', methods=['POST'])
def addUpdatePBX():
    gwid = request.form['gwid']
    name = request.form['name']
    ip_addr = request.form['ip_addr']
    strip = request.form['strip']
    prefix = request.form['prefix']
    # Adding
    if len(gwid) <= 0:
        print(name)
        Gateway = Gateways(name,ip_addr,strip,prefix,settings.FLT_PBX)
        Addr=Address(name,ip_addr,32,settings.FLT_PBX)
        db.add(Gateway)
        db.add(Addr)
        db.commit()
        return displayPBX()
    # Updating
    else:
        db.query(Gateways).filter(Gateways.gwid==gwid).update({'description':"name:"+name,'address':ip_addr,'strip':strip,'pri_prefix':prefix})
        #TODO: You will end up with multiple Address records -will fix
        Addr=Address(name,ip_addr,32,settings.FLT_PBX)
        db.add(Addr)
        db.commit()
        return displayPBX()

@app.route('/pbxdelete',methods=['POST'])
def deletePBX():
    gwid = request.form['gwid']
    name = request.form['name']
    d = db.query(Gateways).filter(Gateways.gwid==gwid)
    d.delete(synchronize_session=False)
    a = db.query(Address).filter(Address.tag=='name:'+name)
    a.delete(synchronize_session=False)
    return displayPBX()

@app.route('/inboundmapping')
def displayInboundMapping(db_err=0):
    if session.get('logged_in'):
        try:
            res = db.execute('select * from dr_rules r,dr_gateways g where r.gwlist = g.gwid and r.groupid > 8000') 
            gateways = db.query(Gateways).filter(Gateways.type==settings.FLT_PBX).all()
            return render_template('inboundmapping.html',rows=res,gwlist=gateways)
        except:
            if db_err <= 3:
               db.rollback()
               db_err=db_err + 1
               return displayInboundMapping(db_err)
            else:
              return render_template('error.html',type="db")

    else:
       return index()

@app.route('/inboundmapping', methods=['POST'])
def addInboundMapping():
    if request.form['ruleid']:
       ruleid = request.form['ruleid']
    else:
       ruleid = None
    gwid = request.form['gwid']
    prefix = request.form['prefix']
    # Adding
    if not ruleid:
       groupid=9000
       IMap  = InboundMapping(groupid,prefix,gwid)
       db.add(IMap)
       db.commit()       
    # Updating
    else:
       db.query(InboundMapping).filter(InboundMapping.ruleid==ruleid).update({'prefix':prefix,'gwlist':gwid})
       db.commit()
    return  displayInboundMapping()

@app.route('/inboundmappingdelete',methods=['POST'])
def deleteInboundMapping():
    ruleid = request.form['ruleid']
    d = db.query(InboundMapping).filter(InboundMapping.ruleid==ruleid)
    d.delete(synchronize_session=False)
    return  displayInboundMapping()


@app.route('/outboundroutes')
def displayOutboundRoutes(db_err=0):
    if session.get('logged_in'):
        try:
           gwlist = db.query(OutboundRoutes.gwlist).filter(OutboundRoutes.groupid==8000).scalar()
           return render_template('outboundroutes.html',outboundroutes=gwlist)
        except:
            if db_err <= 3:
                db.rollback()
                db_err=db_err + 1	
                return displayPBX(db_err)
            else:
                return render_template('error.html',type="db")
    else:
       return index()

@app.route('/outboundroutes', methods=['POST'])
def addUpateOutboundRoutes():
    if request.form['gwlist']:
       gwlist = request.form['gwlist']
    else:
       gwlist = None
    # Adding
    if not gwlist:
       groupid=8000
       prefix = "."
       OMap  = OutboundRoutes(groupid=groupid,prefix='.',gwlist=gwlist,timerec='',routeid='')
       db.add(OMap)
       db.commit()
    # Updating
    else:
       db.query(OutboundRoutes).filter(OutboundRoutes.groupid==8000).update({'gwlist':gwlist})
       db.commit()
    return  displayOutboundRoutes()


@app.route('/reloadkam')
def reloadkam():
       try:
           subprocess.call(['kamcmd' ,'permissions.addressReload'])
           subprocess.call(['kamcmd','drouting.reload'])
           session['last_page'] = request.headers['Referer']
           return render_template('dashboard.html',reloadstatus='successful')
       except:
           return render_template('dashboard.html',reloadstatus='failed')
           
    


manager = Manager(app)

def init_app(flask_app):
    #Setup the Flask session manager with a random secret key
    app.secret_key = os.urandom(12)

    #Add jinga2 filter
    app.jinja_env.filters["attrFilter"]=attrFilter

    #db.init_app(flask_app)
    #db.app = app

    manager.run()

def attrFilter(list,field):
    if ":" in list:    
        d = dict(item.split(":") for item in list.split(","))
        try:
            return d[field]
        except:
            return
    else:
        return list

if __name__ == "__main__":
    init_app(app)
