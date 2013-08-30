/*!
 * Author: Paul Massey, Scriptwerx.co.uk
 *
 * http://scriptwerx.github.io/Mustache.as
 *
 * ActionScript 3.0 translation of:
 * http://github.com/janl/mustache.js
 */

package uk.co.scriptwerx.mustache
{
    public class Scanner
    {
        private var _string:String;
        private var _tail:String;
        private var _pos:uint;

        /**
         * Class constructor
         * @param string
         */

        public function Scanner (string:String)
        {
            _string = string;
            _tail = string;
            _pos = 0;
        }

        /**
         * Returns `true` if the tail is empty (end of string).
         */

        public function eos ():Boolean
        {
            return _tail === "";
        };

        /**
         * Tries to match the given regular expression at the current position.
         * Returns the matched text if it can match, the empty string otherwise.
         *
         * @param re
         * @return
         */

        public function scan (re:RegExp):String
        {
            var match:Array = _tail.match (re);

            if (match && match.index === 0)
            {
                _tail = _tail.substring (match[0].length);
                _pos += match[0].length;
                return match[0];
            }

            return "";
        }

        /**
         * Skips all text until the given regular expression can be matched. Returns
         * the skipped string, which is the entire tail if no match can be made.
         *
         * @param re
         * @return
         */

        public function scanUntil (re:RegExp):String
        {
            var match:String;
            var pos:Number = _tail.search (re);

            switch (pos)
            {
                case -1:
                    match = _tail;
                    pos += _tail.length;
                    _tail = "";
                break;
                case 0:
                    match = "";
                break;
                default:
                    match = _tail.substring (0, pos);
                    _tail = _tail.substring (pos);
                    pos += pos;
            }

            return match;
        }

        /**
         *
         */

        public function get pos ():uint
        {
            return _pos;
        }
    }
}
