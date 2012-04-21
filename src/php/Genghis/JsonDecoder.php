<?php

/**
 * A lenient JSON decoder derived from Services_JSON.
 *
 * JSON (JavaScript Object Notation) is a lightweight data-interchange
 * format. It is easy for humans to read and write. It is easy for machines
 * to parse and generate. It is based on a subset of the JavaScript
 * Programming Language, Standard ECMA-262 3rd Edition - December 1999.
 * This feature can also be found in  Python. JSON is a text format that is
 * completely language independent but uses conventions that are familiar
 * to programmers of the C-family of languages, including C, C++, C#, Java,
 * JavaScript, Perl, TCL, and many others. These properties make JSON an
 * ideal data-interchange language.
 *
 * This package provides a simple decoder for JSON notation.
 *
 * All strings should be in ASCII or UTF-8 format!
 *
 * LICENSE: Redistribution and use in source and binary forms, with or
 * without modification, are permitted provided that the following
 * conditions are met: Redistributions of source code must retain the
 * above copyright notice, this list of conditions and the following
 * disclaimer. Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
 * NO EVENT SHALL CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * @author      Michal Migurski <mike-json@teczno.com>
 * @author      Matt Knapp <mdknapp[at]gmail[dot]com>
 * @author      Brett Stimmerman <brettstimmerman[at]gmail[dot]com>
 * @author      Justin Hileman <justin@justinhileman.info>
 * @copyright   2005 Michal Migurski
 * @license     http://www.opensource.org/licenses/bsd-license.php
 */

/**
 * Converts from JSON format.
 *
 * Brief example of use:
 *
 * <code>
 * // create a new instance of JsonDecoder
 * $json = new JsonDecoder;
 *
 * // accept incoming POST data, assumed to be in JSON notation
 * $input = file_get_contents('php://input', 1000000);
 * $value = $json->decode($input);
 * </code>
 */
class Genghis_JsonDecoder
{
    /**
     * Marker constant for Services_JSON::decode(), used to flag stack state
     */
    const SLICE = 1;

    /**
     * Marker constant for Services_JSON::decode(), used to flag stack state
     */
    const IN_STR = 2;

    /**
     * Marker constant for Services_JSON::decode(), used to flag stack state
     */
    const IN_ARR = 3;

    /**
     * Marker constant for Services_JSON::decode(), used to flag stack state
     */
    const IN_OBJ = 4;

    /**
     * Marker constant for Services_JSON::decode(), used to flag stack state
     */
    const IN_CMT = 5;

    /**
     * Marker constant for Services_JSON::decode(), used to flag stack state
     */
    const IN_REGEX = 6;


   /**
    * constructs a new JsonDecoder instance
    */
    function __construct()
    {
        $this->_mb_strlen            = function_exists('mb_strlen');
        $this->_mb_convert_encoding  = function_exists('mb_convert_encoding');
        $this->_mb_substr            = function_exists('mb_substr');
    }
    // private - cache the mbstring lookup results..
    var $_mb_strlen = false;
    var $_mb_substr = false;
    var $_mb_convert_encoding = false;

   /**
    * convert a string from one UTF-16 char to one UTF-8 char
    *
    * Normally should be handled by mb_convert_encoding, but
    * provides a slower PHP-only method for installations
    * that lack the multibye string extension.
    *
    * @param    string  $utf16  UTF-16 character
    * @return   string  UTF-8 character
    * @access   private
    */
    function utf162utf8($utf16)
    {
        // oh please oh please oh please oh please oh please
        if($this->_mb_convert_encoding) {
            return mb_convert_encoding($utf16, 'UTF-8', 'UTF-16');
        }

        $bytes = (ord($utf16{0}) << 8) | ord($utf16{1});

        switch(true) {
            case ((0x7F & $bytes) == $bytes):
                // this case should never be reached, because we are in ASCII range
                // see: http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8
                return chr(0x7F & $bytes);

            case (0x07FF & $bytes) == $bytes:
                // return a 2-byte UTF-8 character
                // see: http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8
                return chr(0xC0 | (($bytes >> 6) & 0x1F))
                     . chr(0x80 | ($bytes & 0x3F));

            case (0xFFFF & $bytes) == $bytes:
                // return a 3-byte UTF-8 character
                // see: http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8
                return chr(0xE0 | (($bytes >> 12) & 0x0F))
                     . chr(0x80 | (($bytes >> 6) & 0x3F))
                     . chr(0x80 | ($bytes & 0x3F));
        }

        // ignoring UTF-32 for now, sorry
        return '';
    }

   /**
    * convert a string from one UTF-8 char to one UTF-16 char
    *
    * Normally should be handled by mb_convert_encoding, but
    * provides a slower PHP-only method for installations
    * that lack the multibye string extension.
    *
    * @param    string  $utf8   UTF-8 character
    * @return   string  UTF-16 character
    * @access   private
    */
    function utf82utf16($utf8)
    {
        // oh please oh please oh please oh please oh please
        if($this->_mb_convert_encoding) {
            return mb_convert_encoding($utf8, 'UTF-16', 'UTF-8');
        }

        switch($this->strlen8($utf8)) {
            case 1:
                // this case should never be reached, because we are in ASCII range
                // see: http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8
                return $utf8;

            case 2:
                // return a UTF-16 character from a 2-byte UTF-8 char
                // see: http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8
                return chr(0x07 & (ord($utf8{0}) >> 2))
                     . chr((0xC0 & (ord($utf8{0}) << 6))
                         | (0x3F & ord($utf8{1})));

            case 3:
                // return a UTF-16 character from a 3-byte UTF-8 char
                // see: http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8
                return chr((0xF0 & (ord($utf8{0}) << 4))
                         | (0x0F & (ord($utf8{1}) >> 2)))
                     . chr((0xC0 & (ord($utf8{1}) << 6))
                         | (0x7F & ord($utf8{2})));
        }

        // ignoring UTF-32 for now, sorry
        return '';
    }

   /**
    * reduce a string by removing leading and trailing comments and whitespace
    *
    * @param    $str    string      string value to strip of comments and whitespace
    *
    * @return   string  string value stripped of comments and whitespace
    * @access   private
    */
    function reduce_string($str)
    {
        $str = preg_replace(array(

                // eliminate single line comments in '// ...' form
                '#^\s*//(.+)$#m',

                // eliminate multi-line comments in '/* ... */' form, at start of string
                '#^\s*/\*(.+)\*/#Us',

                // eliminate multi-line comments in '/* ... */' form, at end of string
                '#/\*(.+)\*/\s*$#Us'

            ), '', $str);

        // eliminate extraneous space
        return trim($str);
    }

   /**
    * decodes a JSON string into appropriate variable
    *
    * @param    string  $str    JSON-formatted string
    *
    * @return   mixed   number, boolean, string, array, or object
    *                   corresponding to given JSON input string.
    *                   See argument 1 to Services_JSON() above for object-output behavior.
    *                   Note that decode() always returns strings
    *                   in ASCII or UTF-8 format!
    *
    * @throws   Genghis_JsonException
    * @access   public
    */
    function decode($str)
    {
        $str = $this->reduce_string($str);

        switch (strtolower($str)) {
            case 'true':
                return true;

            case 'false':
                return false;

            case 'null':
                return null;

            default:
                $m = array();

                if (is_numeric($str)) {
                    // Lookie-loo, it's a number

                    // This would work on its own, but I'm trying to be
                    // good about returning integers where appropriate:
                    // return (float)$str;

                    // Return float or int, as appropriate
                    return ((float)$str == (integer)$str)
                        ? (integer)$str
                        : (float)$str;

                } elseif (preg_match('/^("|\').*(\1)$/s', $str, $m) && $m[1] == $m[2]) {
                    // STRINGS RETURNED IN UTF-8 FORMAT
                    $delim = $this->substr8($str, 0, 1);
                    $chrs = $this->substr8($str, 1, -1);
                    $utf8 = '';
                    $strlen_chrs = $this->strlen8($chrs);

                    for ($c = 0; $c < $strlen_chrs; ++$c) {

                        $substr_chrs_c_2 = $this->substr8($chrs, $c, 2);
                        $ord_chrs_c = ord($chrs{$c});

                        switch (true) {
                            case $substr_chrs_c_2 == '\b':
                                $utf8 .= chr(0x08);
                                ++$c;
                                break;
                            case $substr_chrs_c_2 == '\t':
                                $utf8 .= chr(0x09);
                                ++$c;
                                break;
                            case $substr_chrs_c_2 == '\n':
                                $utf8 .= chr(0x0A);
                                ++$c;
                                break;
                            case $substr_chrs_c_2 == '\f':
                                $utf8 .= chr(0x0C);
                                ++$c;
                                break;
                            case $substr_chrs_c_2 == '\r':
                                $utf8 .= chr(0x0D);
                                ++$c;
                                break;

                            case $substr_chrs_c_2 == '\\"':
                            case $substr_chrs_c_2 == '\\\'':
                            case $substr_chrs_c_2 == '\\\\':
                            case $substr_chrs_c_2 == '\\/':
                                if (($delim == '"' && $substr_chrs_c_2 != '\\\'') ||
                                   ($delim == "'" && $substr_chrs_c_2 != '\\"')) {
                                    $utf8 .= $chrs{++$c};
                                }
                                break;

                            case preg_match('/\\\u[0-9A-F]{4}/i', $this->substr8($chrs, $c, 6)):
                                // single, escaped unicode character
                                $utf16 = chr(hexdec($this->substr8($chrs, ($c + 2), 2)))
                                       . chr(hexdec($this->substr8($chrs, ($c + 4), 2)));
                                $utf8 .= $this->utf162utf8($utf16);
                                $c += 5;
                                break;

                            case ($ord_chrs_c >= 0x20) && ($ord_chrs_c <= 0x7F):
                                $utf8 .= $chrs{$c};
                                break;

                            case ($ord_chrs_c & 0xE0) == 0xC0:
                                // characters U-00000080 - U-000007FF, mask 110XXXXX
                                //see http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8
                                $utf8 .= $this->substr8($chrs, $c, 2);
                                ++$c;
                                break;

                            case ($ord_chrs_c & 0xF0) == 0xE0:
                                // characters U-00000800 - U-0000FFFF, mask 1110XXXX
                                // see http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8
                                $utf8 .= $this->substr8($chrs, $c, 3);
                                $c += 2;
                                break;

                            case ($ord_chrs_c & 0xF8) == 0xF0:
                                // characters U-00010000 - U-001FFFFF, mask 11110XXX
                                // see http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8
                                $utf8 .= $this->substr8($chrs, $c, 4);
                                $c += 3;
                                break;

                            case ($ord_chrs_c & 0xFC) == 0xF8:
                                // characters U-00200000 - U-03FFFFFF, mask 111110XX
                                // see http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8
                                $utf8 .= $this->substr8($chrs, $c, 5);
                                $c += 4;
                                break;

                            case ($ord_chrs_c & 0xFE) == 0xFC:
                                // characters U-04000000 - U-7FFFFFFF, mask 1111110X
                                // see http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8
                                $utf8 .= $this->substr8($chrs, $c, 6);
                                $c += 5;
                                break;

                        }

                    }

                    return $utf8;

                } elseif (preg_match('/^\[.*\]$/s', $str) || preg_match('/^\{.*\}$/s', $str)) {
                    // array, or object notation

                    if ($str{0} == '[') {
                        $stk = array(self::IN_ARR);
                        $arr = array();
                    } else {
                        $stk = array(self::IN_OBJ);
                        $obj = array();
                    }

                    array_push($stk, array('what'  => self::SLICE,
                                           'where' => 0,
                                           'delim' => false));

                    $chrs = $this->substr8($str, 1, -1);
                    $chrs = $this->reduce_string($chrs);

                    if ($chrs == '') {
                        if (reset($stk) == self::IN_ARR) {
                            return $arr;

                        } else {
                            return $obj;

                        }
                    }


                    $strlen_chrs = $this->strlen8($chrs);

                    for ($c = 0; $c <= $strlen_chrs; ++$c) {

                        $top = end($stk);
                        $substr_chrs_c_2 = $this->substr8($chrs, $c, 2);

                        if (($c == $strlen_chrs) || (($chrs{$c} == ',') && ($top['what'] == self::SLICE))) {
                            // found a comma that is not inside a string, array, etc.,
                            // OR we've reached the end of the character list
                            $slice = $this->substr8($chrs, $top['where'], ($c - $top['where']));
                            array_push($stk, array('what' => self::SLICE, 'where' => ($c + 1), 'delim' => false));

                            if (reset($stk) == self::IN_ARR) {
                                // we are in an array, so just push an element onto the stack
                                array_push($arr, $this->decode($slice));

                            } elseif (reset($stk) == self::IN_OBJ) {
                                // we are in an object, so figure
                                // out the property name and set an
                                // element in an associative array,
                                // for now
                                $parts = array();

                               if (preg_match('/^\s*(["\'].*[^\\\]["\'])\s*:/Uis', $slice, $parts)) {
                                  // "name":value pair
                                    $key = $this->decode($parts[1]);
                                    $val = $this->decode(trim(substr($slice, strlen($parts[0])), ", \t\n\r\0\x0B"));
                                    $obj[$key] = $val;
                                } elseif (preg_match('/^\s*([\p{L}\p{Nl}$_][\p{L}\p{Nl}$\p{Mn}\p{Mc}\p{Nd}\p{Pc}]*)\s*:/Uis', $slice, $parts)) {
                                    // name:value pair, where name is unquoted
                                    $key = $parts[1];
                                    $val = $this->decode(trim(substr($slice, strlen($parts[0])), ", \t\n\r\0\x0B"));
                                    $obj[$key] = $val;
                                } else {
                                    throw new Genghis_JsonException;
                                }
                            }

                        } elseif ((($chrs{$c} == '"') || ($chrs{$c} == "'")) && ($top['what'] != self::IN_STR)) {
                            // found a quote, and we are not inside a string
                            array_push($stk, array('what' => self::IN_STR, 'where' => $c, 'delim' => $chrs{$c}));

                        } elseif (($chrs{$c} == $top['delim']) &&
                                 ($top['what'] == self::IN_STR) &&
                                 (($this->strlen8($this->substr8($chrs, 0, $c)) - $this->strlen8(rtrim($this->substr8($chrs, 0, $c), '\\'))) % 2 != 1)) {
                            // found a quote, we're in a string, and it's not escaped
                            // we know that it's not escaped becase there is _not_ an
                            // odd number of backslashes at the end of the string so far
                            array_pop($stk);

                        } elseif (($chrs{$c} == '[') &&
                                 in_array($top['what'], array(self::SLICE, self::IN_ARR, self::IN_OBJ))) {
                            // found a left-bracket, and we are in an array, object, or slice
                            array_push($stk, array('what' => self::IN_ARR, 'where' => $c, 'delim' => false));

                        } elseif (($chrs{$c} == ']') && ($top['what'] == self::IN_ARR)) {
                            // found a right-bracket, and we're in an array
                            array_pop($stk);

                        } elseif (($chrs{$c} == '{') &&
                                 in_array($top['what'], array(self::SLICE, self::IN_ARR, self::IN_OBJ))) {
                            // found a left-brace, and we are in an array, object, or slice
                            array_push($stk, array('what' => self::IN_OBJ, 'where' => $c, 'delim' => false));

                        } elseif (($chrs{$c} == '}') && ($top['what'] == self::IN_OBJ)) {
                            // found a right-brace, and we're in an object
                            array_pop($stk);

                        } elseif (($substr_chrs_c_2 == '/*') &&
                                 in_array($top['what'], array(self::SLICE, self::IN_ARR, self::IN_OBJ))) {
                            // found a comment start, and we are in an array, object, or slice
                            array_push($stk, array('what' => self::IN_CMT, 'where' => $c, 'delim' => false));
                            $c++;

                        } elseif (($substr_chrs_c_2 == '*/') && ($top['what'] == self::IN_CMT)) {
                            // found a comment end, and we're in one now
                            array_pop($stk);
                            $c++;

                            for ($i = $top['where']; $i <= $c; ++$i)
                                $chrs = substr_replace($chrs, ' ', $i, 1);


                        }

                    }

                    if (in_array($top['what'], array(self::IN_CMT, self::IN_STR))) {
                        throw new Genghis_JsonException;
                    }

                    if (reset($stk) == self::IN_ARR) {
                        return $arr;
                    } elseif (reset($stk) == self::IN_OBJ) {
                        return $obj;
                    }

                } elseif (preg_match('/^\/.*\/$/s', $str)) {
                    // Special case: this is a regex.
                    return new Genghis_JsonRegex($str);
                } else {
                    throw new Genghis_JsonException;
                }
        }
    }

    /**
    * Calculates length of string in bytes
    * @param string
    * @return integer length
    */
    function strlen8( $str )
    {
        if ( $this->_mb_strlen ) {
            return mb_strlen( $str, "8bit" );
        }
        return strlen( $str );
    }

    /**
    * Returns part of a string, interpreting $start and $length as number of bytes.
    * @param string
    * @param integer start
    * @param integer length
    * @return integer length
    */
    function substr8( $string, $start, $length=false )
    {
        if ( $length === false ) {
            $length = $this->strlen8( $string ) - $start;
        }
        if ( $this->_mb_substr ) {
            return mb_substr( $string, $start, $length, "8bit" );
        }
        return substr( $string, $start, $length );
    }
}

class Genghis_JsonRegex
{
    public $pattern;

    public function __construct($pattern)
    {
        $this->pattern = $pattern;
    }

    public function __toString()
    {
        return $this->getPattern();
    }
}

class Genghis_JsonException extends Exception {}

