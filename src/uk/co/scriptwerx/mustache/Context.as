/*!
 * Author: Paul Massey, Scriptwerx.co.uk
 *
 * http://github.com/scriptwerx/mustache.as
 *
 * ActionScript 3.0 translation of:
 * http://github.com/janl/mustache.js
 */

package uk.co.scriptwerx.mustache
{
    public class Context
    {
        private var _view:*;
        private var _parent:Context;
        private var _cache:Object;

        public function Context (view:*, parent:Context = null)
        {
            _view = view || {};
            _parent = parent;
            _cache = {};
        }

        public static function make (view:*):Context
        {
            return (view is Context) ? view : new Context (view);
        }

        public function push (view:*):Context
        {
            return new Context (view, this);
        }

        public function lookup (name:String):*
        {
            var value:* = _cache[name];

            if (!value)
            {
                if (name == '.') value = _view;
                else
                {
                    var context:Context = new Context (_view, this);

                    while (context)
                    {
                        if (name.indexOf ('.') != -1)
                        {
                            value = context._view;
                            var names:Array = name.split ('.');
                            var i:uint = 0;

                            while (value && i < names.length)
                            {
                                try
                                {
                                    value = value[names[i ++]];
                                }
                                catch (e:Error)
                                {
                                    throw new Error ("Error in mustache template: " + e.message);
                                }
                            }
                        }
                        else value = _view[name];

                        if (value != null) break;

                        context = context._parent;
                    }
                }

                _cache[name] = value;
            }

            if (typeof value === 'function') value = value.call (_view);

            return value;
        }

        public function get view ():*
        {
            return _view;
        }
    }
}
