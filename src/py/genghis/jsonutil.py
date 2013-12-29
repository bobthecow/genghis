import bson, json, re, base64, datetime

def as_json(object_):
    return _enc(object_)  # TODO check for types: Array, Hash, BSON::OrderedHash, Genghis::Models::Query

def encode(object_):
    return json.dumps(as_json(object_))

def decode(str_):
    return _dec(json.loads(str_))

def _enc_time(o):
    # strip trailing microsecond zeros, because wtf.
    return o.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + "Z"

def _is_time(o):
    return hasattr(o, "strftime")

def _is_regexp(o):
    return all(hasattr(o, field) for field in ["pattern", "flags", "match", "sub"])  # stupid typecheck

def _enc(o):
    if hasattr(o, "as_json"):  # for Query model
        return _enc(o.as_json())
    elif hasattr(o, "iteritems"):  # dict
        return {k:_enc(v) for k,v in o.iteritems()}
    elif hasattr(o, "__iter__"):  # array
        return [_enc(i) for i in o]
    elif _is_time(o):
        return _thunk("ISODate", _enc_time(o))
    elif _is_regexp(o):
        return _thunk("RegExp", { "$pattern" : o.pattern, "$flags" : _enc_re_flags(o.flags)})
    elif isinstance(o, bson.objectid.ObjectId):
        return _thunk("ObjectId", str(o))
    elif isinstance(o, bson.dbref.DBRef):
        return _db_ref(o)
    elif isinstance(o, bson.binary.Binary):
        return _thunk("BinData", { "$subtype" : o.subtype, "$binary" : _enc_bin_data(o) })
    else:
        return o


def _thunk(name, value):
    return {
        '$genghisType' : name,
        '$value' : value
    }

def _enc_re_flags(opt):
    return ('m' if (opt & re.MULTILINE) else '') + ('i' if (opt & re.IGNORECASE) else '')

def _enc_bin_data(o):
    return base64.b64encode(str(o))

def _db_ref(o):
    ns = (o.database + ".") if o.database is not None else ""
    ns += o.collection
    return {
        '$ref' : ns,
        '$id' : _enc(o.id)
    }

def _dec(o):
    if hasattr(o, "iteritems"):
        if o.has_key("$genghisType"):
            if o['$genghisType'] == "ObjectId":
                return _mongo_object_id(o['$value'])
            if o['$genghisType'] == "ISODate":
                return _mongo_iso_date(o['$value'])
            if o['$genghisType'] == "RegExp":
                return _mongo_reg_exp(o['$value'])
            if o['$genghisType'] == "BinData":
                return _mongo_bin_data(o['$value'])
        return {k:_dec(v) for k,v in o.iteritems()}
    elif hasattr(o, "__iter__"):
        return [_dec(i) for i in o]
    else:
        return o

def _dec_re_flags(flags):
    f = flags or ''
    return (re.MULTILINE if f.find('m')>=0 else 0) | (re.IGNORECASE if f.find('i')>=0 else 0)

def _mongo_object_id(value):
    return bson.objectid.ObjectId(value)

def _mongo_iso_date(value):
    if value is None:
        return datetime.datetime.now()
    return datetime.datetime.strptime(value, '%Y-%m-%dT%H:%M:%S.%fZ')

def _mongo_reg_exp(value):
    return re.compile(value['$pattern'], _dec_re_flags(value['$flags']))

def _mongo_bin_data(value):
    return bson.binary.Binary(base64.b64decode(value['$binary']), value['$subtype'])

