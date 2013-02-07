<?php

class Genghis_ErrorException extends ErrorException
{
    /**
     * Construct a Genghis ErrorException.
     *
     * @param string    $message  (default: "")
     * @param int       $code     (default: 0)
     * @param int       $severity (default: 1)
     * @param string    $filename (default: null)
     * @param int       $lineno   (default: null)
     * @param Exception $previous (default: null)
     */
    public function __construct($message = "", $code = 0, $severity = 1, $filename = null, $lineno = null, $previous = null)
    {
        switch ($severity) {
            case E_WARNING:
            case E_CORE_WARNING:
            case E_COMPILE_WARNING:
            case E_USER_WARNING:
                $type = 'warning';
                break;

            case E_STRICT:
                $type = 'Strict error';
                break;

            default:
                $type = 'error';
                break;
        }

        $message = sprintf('PHP %s:  %s', $type, $message);
        parent::__construct($message, $code, $severity, $filename, $lineno, $previous);
    }

    /**
     * Helper for throwing an ErrorException.
     *
     * This allows us to:
     *
     *     set_error_handler(array('Genghis_ErrorException', 'throwException'));
     *
     * @param int    $errno   Error type
     * @param string $errstr  Message
     * @param string $errfile Filename
     * @param int    $errline Line number
     *
     * @return void
     */
    public static function throwException($errno, $errstr, $errfile, $errline)
    {
        throw new self($errstr, 0, $errno, $errfile, $errline);
    }
}
