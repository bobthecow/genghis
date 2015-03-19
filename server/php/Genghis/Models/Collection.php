<?php

class Genghis_Models_Collection implements ArrayAccess, Genghis_JsonEncodable
{
    public $database;
    public $collection;

    public function __construct(Genghis_Models_Database $database, MongoCollection $collection)
    {
        $this->database   = $database;
        $this->collection = $collection;
    }

    public function offsetExists($id)
    {
        try {
            $this->findDocument($id);
        } catch (Genghis_HttpException $e) {
            if ($e->getStatus() == 404) {
                return false;
            } else {
                // catch and release
                throw $e;
            }
        }

        return true;
    }

    public function offsetGet($id)
    {
        return $this->findDocument($id);
    }

    public function offsetSet($id, $doc)
    {
        $this->findDocument($id);

        $query = array('_id' => $this->thunkMongoId($id));

        try {
            $result = $this->collection->update($query, $doc, self::safe());
        } catch (MongoCursorException $e) {
            if (isset($e->doc)) {
                $doc = $e->doc;
            } elseif (isset($e->document)) {
                $doc = $e->document;
            } else {
                $doc = array('err' => $e->getMessage()); // Ugh. Is not pretty.
            }
            throw new Genghis_HttpException(400, ucfirst($doc['err']));
        }

        if (!(isset($result['ok']) && $result['ok'])) {
            throw new Genghis_HttpException;
        }
    }

    public function offsetUnset($id)
    {
        $this->findDocument($id);

        $query  = array('_id' => $this->thunkMongoId($id));
        $result = $this->collection->remove($query, self::safe());

        if (!(isset($result['ok']) && $result['ok'])) {
            throw new Genghis_HttpException;
        }
    }

    public function getFile($id)
    {
        $mongoId = $this->thunkMongoId($id);
        if (!$mongoId instanceof MongoId) {
            // for some reason this only works with MongoIds?
            throw new Genghis_HttpException(404, sprintf("GridFS file '%s' not found", $id));
        }

        $file = $this->getGrid()->get($mongoId);
        if (!$file) {
            throw new Genghis_HttpException(404, sprintf("GridFS file '%s' not found", $id));
        }

        return $file;
    }

    public function putFile($doc)
    {
        $grid = $this->getGrid();

        if (!property_exists($doc, 'file')) {
            throw new Genghis_HttpException(400, 'Missing file');
        }
        $file = $doc->file;
        unset($doc->file);

        $extra = array();
        foreach ($doc as $key => $val) {
            if (!in_array($key, array('_id', 'filename', 'contentType', 'metadata'))) {
                throw new Genghis_HttpException(400, sprintf("Unexpected property: '%s'", $key));
            }

            if ($key === 'metadata') {
                $encoded = json_encode($val);
                if ($encoded == '{}' || $encoded == '[]') {
                    continue;
                }
            }

            // why the eff doesn't this accept an object like everything else? ugh.
            $extra[$key] = $val;
        }

        $id = $grid->storeBytes($this->decodeFile($file), $extra);

        return $this->findDocument($id);
    }

    public function deleteFile($id)
    {
        $mongoId = $this->thunkMongoId($id);
        if (!$mongoId instanceof MongoId) {
            // for some reason this only works with MongoIds?
            throw new Genghis_HttpException(404, sprintf("GridFS file '%s' not found", $id));
        }

        $grid = $this->getGrid();

        // For some reason it'll happily delete something that doesn't exist :-/
        $file = $grid->get($mongoId);
        if (!$file) {
            throw new Genghis_HttpException(404, sprintf("GridFS file '%s' not found", $id));
        }

        $result = $grid->delete($mongoId);
        if (!$result) {
            throw new Genghis_HttpException;
        }
    }

    public function explainQuery($query = null)
    {
        $query  = $this->decodeQuery($query);
        $result = $this->collection
            ->find($query ? $query : array())
            ->explain();

        return $result;
    }

    public function findDocuments($query = null, $fields = null, $sort = null, $page = 1)
    {
        $query  = $this->decodeQuery($query);
        $fields = $this->decodeQuery($fields);
        $sort   = $this->decodeQuery($sort);
        $offset = Genghis_Api::PAGE_LIMIT * ($page - 1);

        // Mongo driver < 1.3 couldn't deal with an object for the sort hash, so
        // we'll give it an associative array.
        if (version_compare(Mongo::VERSION, '1.3.0', '<')) {
            $sort = (array) $sort;
        }

        $cursor = $this->collection
            ->find($query ? $query : array(), $fields ? $fields : array())
            ->limit(Genghis_Api::PAGE_LIMIT);

        if (!empty($sort)) {
            $cursor->sort($sort);
        }

        $cursor->skip($offset);

        $count = $cursor->count();

        if (is_array($count) && isset($count['errmsg'])) {
            throw new Genghis_HttpException(400, $count['errmsg']);
        }

        return array(
            'count'     => $count,
            'page'      => $page,
            'pages'     => max(1, ceil($count / Genghis_Api::PAGE_LIMIT)),
            'per_page'  => Genghis_Api::PAGE_LIMIT,
            'offset'    => $offset,
            'documents' => iterator_to_array($cursor, false), // Mongo doesn't use sane keys.
        );
    }

    public function insert($data)
    {
        try {
            $result = $this->collection->insert($data, self::safe());
        } catch (MongoCursorException $e) {
            if (isset($e->doc)) {
                $doc = $e->doc;
            } elseif (isset($e->document)) {
                $doc = $e->document;
            } else {
                $doc = array('err' => $e->getMessage()); // Ugh. Is not pretty.
            }
            throw new Genghis_HttpException(400, ucfirst($doc['err']));
        }

        if (!(isset($result['ok']) && $result['ok'])) {
            throw new Genghis_HttpException;
        }

        return $data;
    }

    public function drop()
    {
        $this->collection->drop();
    }

    public function truncate()
    {
        $indexes = $this->collection->getIndexInfo();
        $this->collection->drop();
        foreach ($indexes as $index) {
            $this->collection->ensureIndex($index['key'], $index);
        }
    }

    public function asJson()
    {
        $name  = $this->collection->getName();
        $colls = $this->database->database->listCollections();
        foreach ($colls as $coll) {
            if ($coll->getName() == $name) {
                return array(
                    'id'      => $coll->getName(),
                    'name'    => $coll->getName(),
                    'count'   => $coll->count(),
                    'indexes' => $coll->getIndexInfo(),
                    'stats'   => $this->stats(),
                );
            }
        }

        throw new Genghis_HttpException(404, sprintf("Collection '%s' not found in '%s'", $name, $this->database->name));
    }

    private function thunkMongoId($id)
    {
        if ($id instanceof MongoId) {
            return $id;
        }

        if ($id[0] == '~') {
            return Genghis_Json::decode(base64_decode(substr($id, 1)));
        }

        return preg_match('/^[a-f0-9]{24}$/i', $id) ? new MongoId($id) : $id;
    }

    private function findDocument($id)
    {
        $doc = $this->collection->findOne(array('_id' => $this->thunkMongoId($id)));
        if (!$doc) {
            throw new Genghis_HttpException(404, sprintf("Document '%s' not found in '%s'", $id, $this->collection->getName()));
        }

        return $doc;
    }

    private function isGridCollection()
    {
        return preg_match('/\.files$/', $this->collection->getName());
    }

    private function getGrid()
    {
        if (!($this->isGridCollection())) {
            $msg = sprintf("GridFS collection '%s' not found in '%s'", $this->collection->getName(), $this->database->name);
            throw new Genghis_HttpException(404, $msg);
        }

        if (!isset($this->grid)) {
            $prefix = preg_replace('/\.files$/', '', $this->collection->getName());
            $this->grid = $this->database->database->getGridFS($prefix);
        }

        return $this->grid;
    }

    private function decodeFile($data)
    {
        $count = 0;
        $data  = preg_replace('/^data:[^;]+;base64,/', '', $data, 1, $count);
        if ($count !== 1) {
            throw new Genghis_HttpException(400, 'File must be a base64 encoded data: URI');
        }

        return base64_decode(str_replace(' ', '+', $data));
    }

    private function decodeQuery($query)
    {
        if (empty($query)) {
            return array();
        }

        try {
            return Genghis_Json::decode($query);
        } catch (Genghis_JsonException $e) {
            throw new Genghis_HttpException(400, 'Malformed document');
        }
    }

    private function stats()
    {
        return $this->database->database->command(array('collStats' => $this->collection->getName()));
    }

    private static function safe()
    {
        if (version_compare(Mongo::VERSION, '1.3.0', '>=')) {
            return array('w' => 1);
        } else {
            return array('safe' => true);
        }
    }
}
