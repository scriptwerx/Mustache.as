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
    public class Mustache
    {
        public const NAME:String = "Mustache.as";
        public const VERSION:String = "0.7.2";

        // All Mustache.* functions use this writer.
        private var defaultWriter:Writer;

        private var entityMap:Object = {
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            '"': '&quot;',
            "'": '&#39;',
            "/": '&#x2F;'
        };

        public function Mustache ()
        {
            defaultWriter = new Writer ();
        };

        // Allow the user to override it.
        // See https://github.com/janl/mustache.js/issues/244

        protected function escapeHtml (string:String):String
        {
            return String (string).replace (/[&<>"'\/]/g, function (s:String):String
            {
                return entityMap[s];
            });
        }

        /**
         * Clears all cached templates and partials in the default writer.
         */

        public function clearCache ():void
        {
            defaultWriter.clearCache ();
        }

        /**
         * Compiles the given `template` to a reusable function using the default
         * writer.
         */

        public function compile (template:String, tags:Array):Function
        {
            return defaultWriter.compile (template, tags);
        }

        /**
         * Compiles the partial with the given `name` and `template` to a reusable
         * function using the default writer.
         */

        public function compilePartial (name:String, template:String, tags:Array = null):String
        {
            return defaultWriter.compilePartial (name, template, tags);
        }

        /**
         * Compiles the given array of tokens (the output of a parse) to a reusable
         * function using the default writer.
         */

        public function compileTokens (tokens:Array, template:String):Function
        {
            return defaultWriter.compileTokens (tokens, template);
        };

        /**
         * Renders the `template` with the given `view` and `partials` using the
         * default writer.
         */

        public function render (template:String, view:Object, partials:Object = null):String
        {
            return defaultWriter.render (template, view, partials);
        }
    }
}
