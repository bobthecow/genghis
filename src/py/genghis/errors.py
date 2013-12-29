

class GenghisException(Exception):
    pass


class MalformedDocument(GenghisException):
    http_status = 400
    def __init__(self, msg='Malformed document'):
        self.message=msg


class NotFound(GenghisException):
    http_status = 404
    message = 'Not found'


class AlreadyExists(GenghisException):
    http_status = 400


class ServerNotFound(NotFound):
    def __init__(self, name):
        self.name = name

    @property
    def message(self):
        return "Server '{name}' not found".format(name=self.name)


class ServerAlreadyExists(AlreadyExists):
    def __init__(self, name):
        self.name = name

    @property
    def message(self):
        return "Server '{name}' already exists".format(name=self.name)


class DatabaseNotFound(NotFound):
    def __init__(self, server, name):
        self.server = server
        self.name = name

    @property
    def message(self):
        return "Database '{name}' not found on '{server.name}'".format(name=self.name,server=self.server)


class DatabaseAlreadyExists(AlreadyExists):
    def __init__(self, server, name):
        self.server = server
        self.name = name

    @property
    def message(self):
        return "Database '{name}' already exists on '{server.name}'".format(name=self.name,server=self.server)


class CollectionNotFound(NotFound):
    def __init__(self, database, name):
        self.database = database
        self.name = name

    @property
    def message(self):
        return "Collection '{name}' not found in '{database.name}'".format(name=self.name,database=self.database)


class GridFSNotFound(CollectionNotFound):
    @property
    def message(self):
        return "GridFS collection '{name}' not found in '{database.name}'".format(name=self.name,database=self.database)


class CollectionAlreadyExists(AlreadyExists):
    def __init__(self, database, name):
        self.database = database
        self.name = name

    @property
    def message(self):
        return "Collection '{name}' already exists in '{database.name}'".format(name=self.name,database=self.database)


class DocumentNotFound(NotFound):
    def __init__(self, collection, doc_id):
        self.collection = collection
        self.doc_id = doc_id

    @property
    def message(self):
        return "Document '{doc_id}' not found in '{collection.name}'".format(doc_id=self.doc_id,collection=self.collection)


class GridFileNotFound(DocumentNotFound):
    @property
    def message(self):
        return "GridFS file '{doc_id}' not found".format(doc_id=self.doc_id,collection=self.collection)
