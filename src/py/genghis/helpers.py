from __future__ import absolute_import
from flask import request
import json
import re
import bson
from genghis.jsonutil import as_json, decode, encode
from werkzeug.exceptions import BadRequest
from genghis.errors import MalformedDocument, ServerAlreadyExists,\
    ServerNotFound
import pymongo
import os
from flask.ctx import after_this_request
import pkg_resources
from flask.helpers import make_response

PAGE_LIMIT = 50

def get_asset(name):
    return pkg_resources.resource_string(__name__, name)

def request_context():  # could make is nicer
    """Cache in request context"""
    if not hasattr(request, "rq_ctx"):
        setattr(request, "rq_ctx", {})
    return getattr(request, "rq_ctx")
    #return request.headers.setdefault("_rq_ctx_", {})

### Genghis JSON responses ###

def jsonify(obj=None, **kwargs):
    obj = obj or kwargs or obj
    response = make_response(encode(obj))
    response.mimetype = 'application/json'
    return response

### Misc request parsing helpers ###

def query_param():
    return decode(request.args.get('q', '{}'))

def page_param():
    return int(request.args.get('page', 1))

def request_json():
    try:
        return decode(request.data)
    except:
        raise MalformedDocument

def thunk_mongo_id(id_):
    return bson.objectid.ObjectId(id_) if re.match("^[a-f0-9]{24}$", id_, re.IGNORECASE) else id_


### Seemed like a good place to put this ###

def server_status_alerts():
    alerts = []
    if not pymongo.has_c():
        alerts.append({
            "level" : "warning",
            "msg" : "You should install the pymongo C extension"
        })
    # TODO: implement rest
    return alerts

### Server management ###

def servers():
    if "servers" not in request_context():
        dsn_list = json.loads(request.cookies.get('genghis_rb_servers', "[]"))
        servers = dict(default_servers().items() + init_servers(dsn_list).items())
        if not servers:
            servers = init_servers(['localhost'])
        request_context()["servers"] = servers
    return request_context()["servers"]

def default_servers():
    servers = os.environ.get("GENGHIS_SERVERS", "")
    servers = servers and servers.split(";") or []
    return init_servers(servers, default=True)

def init_servers(dsn_list, default=False):
    from genghis.models import Server
    servers = [Server(dsn) for dsn in dsn_list]
    for server in servers:
        server.default = default
    return {server.name:server for server in servers}

def add_server(dsn):
    from genghis.models import Server
    server = Server(dsn)
    if server.error:
        raise MalformedDocument(server.error)
    if server.name in servers():
        raise ServerAlreadyExists(server.name)
    servers()[server.name] = server
    save_servers()
    return server

def remove_server(name):
    if name not in servers():
        raise ServerNotFound(name)
    del servers()[name]
    save_servers()

def save_servers():
    dsn_list = [server.dsn for name, server in servers.iteritems() if not server.default]
    # NOTE: Flask's default implementation for sessions is to store the data in a cookie
    @after_this_request
    def remember_servers(response):
        response.set_cookie('genghis_rb_servers', json.dumps(dsn_list), max_age=60*60*24*365)
