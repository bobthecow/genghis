from __future__ import absolute_import
from genghis.helpers import server_status_alerts, servers, add_server,\
    remove_server, query_param, request_json, page_param, jsonify,\
    get_asset, fields_param, sort_param
from flask import Flask, request
from genghis.errors import ServerNotFound, GenghisException
import pystache
import sys
import logging
from flask.helpers import make_response

VERSION = "1.0.0"  # FIXME: Smarter handling 

logger = logging.getLogger("genghis")
logger.addHandler(logging.StreamHandler(sys.stdout))
# logger.setLevel(logging.DEBUG)    

app = Flask(__name__)

### Error handling ###

def error_response(status, message):
    if request.is_xhr:
        response = jsonify({"error":message, "status":status})
        response.status_code = status
        return response
    else:
        return pystache.render(get_asset("error.html.mustache"), {
            "genghis_version" : VERSION,
            "base_url" : request.url_root,
            "status" : status,
            "message" : message
        })
        
@app.errorhandler(GenghisException)
def handle_api_errors(error):
    return error_response(error.http_status, error.message)  # FIXME: check if we should return extra objects

# NOTE: no special not found handler (catchall could contain it)

### Asset routes ###

@app.route("/css/style.css")
def asset_stylecss():
    response = make_response(get_asset("style.css"))
    response.mimetype = 'text/css'
    return response 

@app.route("/js/script.js")
def asset_scriptjs():
    response = make_response(get_asset("script.js"), )
    response.mimetype = 'text/javascript'
    return response

### Default route ###

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def catch_all(path):
    if request.is_xhr:
        pass
    print request.url_root
    return pystache.render(get_asset("index.html.mustache"), {
        "genghis_version" : VERSION,
        "base_url" : request.url_root[:-1]
    })

### Genghis API ###

@app.route('/check-status')
def check_status():
    try:
        return jsonify(alerts = server_status_alerts())
    except Exception:
        logger.error("Ouch", exc_info=True)


@app.route('/servers', methods=["GET", "POST"])
def servers_():
    if request.method == 'GET':
        return jsonify(servers().values())
    return jsonify(add_server(request.get_json()["url"]))

@app.route('/servers/<server>', methods=["GET", "DELETE"])
def server(server):
    if request.method == 'GET':
        try:
            return jsonify(servers()[server])
        except KeyError:
            raise ServerNotFound(server)
    remove_server(server)
    return jsonify(success=True)

@app.route('/servers/<server>/databases', methods=["GET", "POST"])
def databases(server):
    if request.method == "GET":
        return jsonify(servers()[server].databases)
    return jsonify(servers()[server].create_database(request.get_json()["name"]))

@app.route('/servers/<server>/databases/<database>', methods=["GET", "DELETE"])
def database(server, database):    
    if request.method == "GET":
        return jsonify(servers()[server][database])
    servers()[server][database].drop()
    return jsonify(success=True)

@app.route('/servers/<server>/databases/<database>/collections', methods=["GET", "POST"])
def collections(server, database):    
    if request.method == "GET":
        return jsonify(servers()[server][database].collections)
    return jsonify(servers()[server][database].create_collection(request.get_json()["name"]))

@app.route('/servers/<server>/databases/<database>/collections/<collection>', methods=["GET", "DELETE"])
def collection(server, database, collection):
    if request.method == "GET":
        return jsonify(servers()[server][database][collection])
    servers()[server][database][collection].drop()
    return jsonify(success=True)

@app.route('/servers/<server>/databases/<database>/collections/<collection>', methods=["GET"])
def explain_collection(server, database, collection):
    return jsonify(servers()[server][database][collection].explain(query_param()))

@app.route('/servers/<server>/databases/<database>/collections/<collection>/documents', methods=["GET", "POST", "DELETE"])
def documents(server, database, collection):    
    if request.method == "GET":
        return jsonify(servers()[server][database][collection].documents(query_param(), fields_param(), sort_param(), page_param()))
    elif request.method == "DELETE":
        servers()[server][database][collection].truncate()
        return jsonify(success=True)
    return jsonify(servers()[server][database][collection].insert(request_json()))

@app.route('/servers/<server>/databases/<database>/collections/<collection>/documents/<document>', methods=["GET", "PUT", "DELETE"])
def document(server, database, collection, document):    
    if request.method == "GET":
        return jsonify(servers()[server][database][collection][document])
    elif request.method == "PUT":
        return jsonify(servers()[server][database][collection].update(document, request_json()))
    servers()[server][database][collection].remove(document)
    return jsonify(success=True)

### GridFS handling ###

@app.route('/servers/<server>/databases/<database>/collections/<collection>/files', methods=["POST"])
def files(server, database, collection):
    return jsonify(servers()[server][database][collection].put_file(request_json()))

@app.route('/servers/<server>/databases/<database>/collections/<collection>/files/<document>', methods=["GET", "DELETE"])
def file_document(server, database, collection, document):
    if request.method == "GET":
        file_ = servers()[server][database][collection].get_file(document)
        content_type = file_.content_type or 'binary/octet-stream'
        filename = file_.filename or document
        response = make_response(iter(file_), mimetype=content_type)
        response.headers["Content-Disposition"] = "attachment; filename={filename}".format(filename=filename)
        return response
    servers()[server][database][collection].delete_file(document)
    return jsonify(success=True)
