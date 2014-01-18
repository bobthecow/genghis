from __future__ import absolute_import
import pymongo
from pymongo.errors import ConnectionFailure, InvalidURI, ConfigurationError,\
    OperationFailure, CollectionInvalid, InvalidName
from pymongo.uri_parser import parse_uri, DEFAULT_PORT
import re
import urlparse
import urllib
import json
import math
from genghis.errors import CollectionAlreadyExists, MalformedDocument,\
    CollectionNotFound, DocumentNotFound, GridFileNotFound,\
    GridFSNotFound, DatabaseAlreadyExists, DatabaseNotFound
from genghis.helpers import thunk_mongo_id
import base64
from gridfs.errors import NoFile
from genghis.jsonutil import decode
import bson
from gridfs import GridFS
import traceback
from gridfs.grid_file import GridOut

class Server(object):
    _client = None
    _info = None
    
    def __init__(self, dsn):
        self.default = False
        self.error = None
        self.db = None
        try:
            self._client = None
            if dsn.find("://")==-1:
                dsn = "mongodb://"+dsn
            dsn, uri = self._get_dsn_and_uri(self._extract_extra_options(dsn))
            
            host, port = uri["nodelist"][0]
            
            name = host
            
            username = uri.get("username", None)
            if username is not None:
                name = username + "@" + name
            
            if port != DEFAULT_PORT:
                name += ":" + str(port)
            
            database = uri.get("database", None)
            if database is not None and database != "admin":
                name += "/" + database
                self.db = database
            
            self.name = name
        except InvalidURI:
            self.error = 'Malformed server DSN'
            self.name = dsn
        self.dsn = dsn

    def create_database(self, db_name):
        if self._does_db_exist(db_name):
            raise DatabaseAlreadyExists(self, db_name)
        try:
            self.client[db_name]['__genghis_tmp_collection__'].drop()
        except InvalidName:
            raise MalformedDocument('Invalid database name')
        return Database(self.client, db_name)
    
    @property
    def databases(self):
        return [Database(self.client, db["name"]) for db in self.info["databases"]]

    def __getitem__(self, db_name):
        if not self._does_db_exist(db_name):
            raise DatabaseNotFound(self, db_name)
        return Database(self.client, db_name)
    
    def as_json(self):
        json = {
            "id" : self.name,
            "name" : self.name,
            "editable" : not self.default
        }
        
        if self.error:
            json["error"] = self.error
        else:
            try:
                info = self.info
                json.update(
                    size = int(info["totalSize"]),
                    count = len(info["databases"]),
                    databases = [db["name"] for db in info["databases"]]
                )
            # except AuthenticationF TODO
            except ConnectionFailure, e:
                # NOTE: e.message might contain non UTF-8 encoding on non US platforms
                json["error"] = "Authentication error: {e.message}".format(e=e)
            except OperationFailure, e:
                json["error"] = "Authentication error: {e.message}".format(e=e)
        return json
    
    def to_json(self):  # ?
        return json.dumps(self.as_json())
    
    def _get_dsn_and_uri(self, dsn):
        try:
            return dsn, parse_uri(dsn)
        except InvalidURI:
            dsn = re.sub("/?$", "/admin", dsn)
            return dsn, parse_uri(dsn)

    def _extract_extra_options(self, dsn):
        opts = {}
        try:
            host, qs = dsn.split("?", 2)
        except ValueError:
            return dsn
        keep = {}
        for opt, value in urlparse.parse_qsl(qs):
            if opt=="replicaSet":
                keep[opt] = value
            elif opt=="connectTimeoutMS":
                try:
                    opts["connect_timeout"] = int(value) / 1000.0
                except ValueError:
                    raise ConfigurationError("Unexpected {opt} option value: {value}".format(opt=opt, value=value))
            elif opt=="ssl":
                if value != True:
                    raise ConfigurationError("Unexpected {opt} option value: {value}".format(opt=opt, value=value))
                opts[opt] = True
            else:
                raise ConfigurationError("Unknown option {opt}".format(opt=opt))
        self.opts = opts
        if keep:
            host += "?" + urllib.urlencode(keep)
        return host

    @property
    def client(self):
        if not self._client:
            try:
                self._client = pymongo.MongoClient(self.dsn)
            except Exception, e:
                raise ConnectionFailure(e.message)
        return self._client
    
    @property
    def info(self):
        if not self._info:
            if self.db is None:
                self._info = self.client.admin.command("listDatabases")
            else:
                stats = self.client[self.db].command("dbStats")
                self._info = {
                    "databases" : [{ "name" : self.db }],
                    "totalSize" : stats["fileSize"]
                }
        return self._info
        
    def _does_db_exist(self, db_name):
        if self.db is None:
            return db_name in self.client.database_names()
        else:
            return self.db == db_name

class Query(object):
    PAGE_LIMIT = 50
    _documents = None
    
    def __init__(self, collection, query=None, page=1):
        self.collection = collection
        self.page = page
        self.query = query or {}
        
    def as_json(self):
        return {
            "count" : self.documents.count(),
            "page" : self.page,
            "pages" : self.pages,
            "per_page" : Query.PAGE_LIMIT,
            "offset" : self.offset,
            "documents" : list(self.documents)
        }
    
    def to_json(self):
        return json.dumps(self.as_json())
    
    @property
    def pages(self):
        return max(0, int(math.ceil(1.0 * self.documents.count() / Query.PAGE_LIMIT)))
    
    @property
    def offset(self):
        return Query.PAGE_LIMIT * (self.page-1)

    @property
    def documents(self):
        if not self._documents:
            self._documents = self.collection.find(self.query, limit=Query.PAGE_LIMIT, skip=self.offset)
        return self._documents
    
class Database(object):
    SYSTEM_COLLECTION_NAMES = ['system.namespaces', 'system.indexes', 'system.profile', 'system.users', 'system.js']
    _collection_names = None
    _collections = None
    _database = None
    _info = None
    _stats = None
    
    def __init__(self, client, name):
        self.client = client
        self.name = name
        
    def drop(self):
        self.database.connection.drop_database(self.database.name)
        
    def create_collection(self, coll_name):
        try:
            return Collection(self.database.create_collection(coll_name))
        except CollectionInvalid:
            raise CollectionAlreadyExists(self, coll_name)
        except Exception:
            raise MalformedDocument('Invalid collection name')

    @property
    def collections(self):
        if self._collections is None:
            self._collections = [Collection(self.database[coll_name]) for coll_name in self.database.collection_names() if not self._is_system_collection_name(coll_name)]
        return self._collections
    
    @property
    def collection_names(self):
        if self._collection_names is None:
            self._collection_names = [coll_name for coll_name in self.database.collection_names() if not self._is_system_collection_name(coll_name)]
        return self._collection_names
    
    def __getitem__(self, coll_name):
        if coll_name not in self.database.collection_names():
            raise CollectionNotFound(self, coll_name)
        return Collection(self.database[coll_name])
    
    def as_json(self):
        try:
            return {
                "id" : self.database.name,
                "name" : self.database.name,
                "count" : len(self.collection_names),
                "collections" : self.collection_names,
                "stats" : self.stats  
            }
        except InvalidName, e:
            return {
                "id" : self.name,
                "name" : self.name,
                "error" : e.message
            }

    def to_json(self):
        return json.dumps(self.as_json())
  
    @property
    def database(self):
        if self._database is None:
            self._database = self.client[self.name]
        return self._database
    
    @property
    def info(self):
        if self._info is None:
            name = self.database.name
            for db in self.database.connection['admin'].command("listDatabases")['databases']:
                if db["name"] == name:
                    break
            else:
                db = None
            self._info = db
        return self._info
            
    @property
    def stats(self):
        if self._stats is None:
            self._stats = self.database.command("dbStats")
        return self._stats
        
    def _is_system_collection_name(self, coll_name):
        return coll_name in Database.SYSTEM_COLLECTION_NAMES;
        
class Collection(object):
    _grid = None
    
    def __init__(self, collection):
        self.collection = collection
    
    def drop(self):
        self.colleciton.drop()
        
    def truncate(self):
        indexes = self.collection.index_information()
        self.colleciton.drop()
        for name, index in indexes.iteritems():
            self.collection.ensure_index(index.pop(), name=name, **index)  # TODO: check if correct
        
    def insert(self, data):
        try:
            id_ = self.collection.insert(data)
            return self.collection.find_one(id_)
        except OperationFailure, e:
            raise MalformedDocument(e.message)
        
    def remove(self, doc_id):
        self[doc_id]
        return self.collection.remove(self._thunk_mongo_id(doc_id))
    
    def update(self, doc_id, data):
        try:
            print self._thunk_mongo_id(doc_id)
            doc = self.collection.find_and_modify(
                query = {'_id' : self._thunk_mongo_id(doc_id)},
                update = data,
                upsert = True
            )
            if doc is None:
                raise DocumentNotFound(self, doc_id)
            return doc
        except OperationFailure, e:
            traceback.print_exc()
            raise MalformedDocument(e.message)
    
    def explain(self, query=None):
        return self.collection.find(query or {}).explain()
    
    def documents(self, query=None, page=1):
        return Query(self.collection, query or {}, page)
    
    def __getitem__(self, doc_id):
        doc = self.collection.find_one(self._thunk_mongo_id(doc_id))
        if doc is None:
            raise DocumentNotFound(self, doc_id)
        return doc
    
    def put_file(self, data):
        NAME_MAP = {
            "filename" : "filename",
            "metadata" : "metadata",
            "_id" : "_id",
            "contentType" : "content_type"
        }

        try:
            file_ = data.pop("file")
        except KeyError:
            raise MalformedDocument("Missing file.")
        
        try:
            opts = {NAME_MAP[k]:v for k,v in data.items() if v}
        except KeyError, e:
            raise MalformedDocument("Unexpected property: '{k}'".format(k=e.message))
        
        id_ = self.grid.put(self._decode_file(file_), **opts)
        return self[id_]
    
    def get_file(self, doc_id):
        try:
            doc = self.grid.get(self._thunk_mongo_id(doc_id))
            if doc is None:
                raise DocumentNotFound(self, doc_id)
            if not self._is_grid_file(doc):
                raise GridFileNotFound(self, doc_id)
            return doc
        except NoFile:
            raise GridFileNotFound(self, doc_id)
    
    def delete_file(self, doc_id):
        self.get_file(doc_id)
        self.grid.delete(self._thunk_mongo_id(doc_id))  # NOTE: have no feedback if succ
        
    def as_json(self):
        return {
            "id" : self.collection.name,
            "name" : self.collection.name,
            "count" : self.collection.count(),
            "indexes" : self.collection.index_information().values(),  # NOTE: key is in dict.items() format, 'ns' and 'name' fields missing
            "stats" : self.collection.database.command("collstats", self.collection.name)
        }
    
    def to_json(self):
        return json.dumps(self.as_json())
    
    def _thunk_mongo_id(self, doc_id):
        if isinstance(doc_id, bson.objectid.ObjectId):
            return doc_id
        elif doc_id[0]=="~":
            doc_id = base64.b64decode(doc_id[1:])
            return decode("{\"_id\":{doc_id}}".format(doc_id=doc_id))['_id']
        else:
            return thunk_mongo_id(doc_id)
    
    def _is_grid_collection(self):
        return self.collection.name.endswith(".files")
    
    @property
    def grid(self):
        if not self._is_grid_collection():
            raise GridFSNotFound(self.collection.database, self.collection.name)
        if self._grid is None:
            self._grid = GridFS(self.collection.database, re.sub("\.files$", "", self.collection.name))
        return self._grid
    
    def _is_grid_file(self, doc):
        return isinstance(doc, GridOut)
    
    def _decode_file(self, data):
        try:
            if not re.match("^data:[^;]+;base64,", data):
                raise ValueError
            return base64.b64decode(re.sub("^data:[^;]+;base64,", "", data))
        except Exception:
            raise MalformedDocument('File must be a base64 encoded data: URI')
