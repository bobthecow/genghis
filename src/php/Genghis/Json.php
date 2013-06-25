<?php

class Genghis_Json
{
    /**
     * Encode a Mongo document into JSON.
     *
     * Serialize special object types (ObjectIds, Dates, RegExps, etc) to a
     * Genghis-specific format, for example, an ObjectId might be serialized as:
     *
     *     {
     *         '$genghisType': 'ObjectId',
     *         '$value': '503f1a53910b4b7863341428'
     *     }
     *
     * @param   mixed $object Object or associative array
     *
     * @return string
     */
    public static function encode($object)
    {
        // $object is not really an object, but what can you do?
        return json_encode(self::doEncode($object));
    }

    private static function doEncode($object)
    {
        if (is_object($object) && $object instanceof Genghis_JsonEncodable) {
            $object = $object->asJson();
        }

        if (is_object($object)) {

            // Genghisify Mongo objects.
            switch (get_class($object)) {
                case 'MongoId':
                    return array(
                        '$genghisType' => 'ObjectId',
                        '$value' => (string) $object
                    );

                case 'MongoDate':
                    $str = gmdate('Y-m-d\TH:i:s', $object->sec);
                    if ($object->usec) {
                        $str .= rtrim(sprintf('.%06d', $object->usec), '0');
                    }
                    $str .= 'Z';

                    return array(
                        '$genghisType' => 'ISODate',
                        '$value'       => $str       // 2012-08-30T06:35:22.056Z
                    );

                case 'MongoRegex':
                    return array(
                        '$genghisType' => 'RegExp',
                        '$value' => array(
                            '$pattern' => $object->regex,
                            '$flags'   => $object->flags ? $object->flags : null
                        )
                    );

                case 'MongoBinData':
                    return array(
                        '$genghisType' => 'BinData',
                        '$value' => array(
                            '$subtype' => $object->type,
                            '$binary'  => base64_encode($object->bin),
                        )
                    );
            }

            // everything else is likely a StdClass...
            foreach ($object as $prop => $value) {
                $object->$prop = self::doEncode($value);
            }

        } elseif (is_array($object)) {
            // walk.
            foreach ($object as $key => $value) {
                $object[$key] = self::doEncode($value);
            }
        } elseif (is_float($object) && is_nan($object)) {
            return array('$genghisType' => 'NaN');
        }

        return $object;
    }

    public static function decode($object)
    {
        if (is_string($object)) {
            $object = json_decode($object);

            if ($object === false) {
                throw new Genghis_JsonException;
            }
        }

        return self::doDecode($object);
    }

    private static function doDecode($object)
    {
        if (is_object($object)) {
            if ($type = self::getProp($object, 'genghisType')) {
                $value = self::getProp($object, 'value');
                switch ($type) {
                    case 'ObjectId':
                        return new MongoId($value);

                    case 'ISODate':
                        if ($value === null) {
                            return new MongoDate;
                        } else {
                            $date = new DateTime($value);

                            return new MongoDate($date->getTimestamp(), (int) $date->format('u'));
                        }

                    case 'RegExp':
                        $pattern = self::getProp($value, 'pattern');
                        $flags   = self::getProp($value, 'flags');

                        return new MongoRegex(sprintf('/%s/%s', $pattern, $flags));

                    case 'BinData':
                        $data = base64_decode(self::getProp($value, 'binary'));
                        $type = self::getProp($value, 'subtype');

                        return new MongoBinData($data, $type);

                    case 'NaN':
                        return NAN;
                }
            } else {
                foreach ($object as $prop => $value) {
                    $object->$prop = self::doDecode($value);
                }
            }
        } elseif (is_array($object)) {
            foreach ($object as $key => $value) {
                $object[$key] = self::doDecode($value);
            }
        }

        return $object;
    }

    private static function getProp($object, $name)
    {
        $name = sprintf('$%s', $name);

        return isset($object->$name) ? $object->$name : null;
    }
}
