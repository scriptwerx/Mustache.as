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
    public class Writer
    {
        private var _cache:Object;
        private var _partialCache:Object;
        private var _loadPartial:*;
        private var template:String;

        private var tags:Array = ["{{", "}}"];
        private var whiteRe:RegExp = /\s*/;
        private var spaceRe:RegExp = /\s+/;
        private var nonSpaceRe:RegExp = /\S/;
        private var eqRe:RegExp = /\s*=/;
        private var curlyRe:RegExp = /\s*\}/;
        private var tagRe:RegExp = /#|\^|\/|>|\{|&|=|!/;

        /**
         * Class constructor
         */

        public function Writer ():void
        {
            clearCache ();
        }

        /**
         *
         */

        public function clearCache ():void
        {
            _cache = {};
            _partialCache = {};
        }

        /**
         *
         * @param template
         * @param tags
         */

        public function compile (template:String, tags:* = null):Function
        {
            var fn:Function = _cache[template];

            if (!fn)
            {
                var tokens:Array = parseTemplate (template, tags);
                fn = _cache[template] = compileTokens (tokens, template);
            }

            return fn;
        }

        /**
         *
         * @param name
         * @param template
         * @param tags
         */

        public function compilePartial (name:String, template:String, tags:* = null):String
        {
            var fn:* = compile (template, tags);
            _partialCache[name] = fn;
            return fn;
        }

        /**
         *
         * @param name
         */

        public function getPartial (name:String):String
        {
            if (!(name in this._partialCache) && _loadPartial)
            {
                compilePartial (name, _loadPartial (name));
            }

            return _partialCache[name];
        }

        /**
         *
         * @param tokens
         * @param template
         */

        public function compileTokens (tokens:Array, template:String):Function
        {
            var self:Writer = this;

            return function (view:*, partials:*):String
            {
                if (partials)
                {
                    if (typeof partials === 'function')
                    {
                        _loadPartial = partials;
                    }
                    else
                    {
                        for (var name:String in partials)
                        {
                            self.compilePartial (name, partials[name]);
                        }
                    }
                }
                return renderTokens (tokens, self, Context.make (view), template);
            }
        }

        /**
         * Breaks up the given `template` string into a tree of token objects. If
         * `tags` is given here it must be an array with two string values: the
         * opening and closing tags used in the template (e.g. ["<%", "%>"]). Of
         * course, the default is to use mustaches (i.e. Mustache.tags).
         *
         * @param p_template
         * @param p_tags
         * @return
         */

        private function parseTemplate (p_template:String, p_tags:*):Array
        {
            template = p_template || '';
            tags = p_tags || tags;

            if (typeof tags === 'string') tags = tags.split(spaceRe);
            if (tags.length !== 2) throw new Error('Invalid tags: ' + tags.join(', '));

            var tagRes:Array = escapeTags (tags);
            var scanner:Scanner = new Scanner (template);

            var sections:Array = [];     // Stack to hold section tokens
            var tokens:Array = [];       // Buffer to hold the tokens
            var spaces:Array = [];       // Indices of whitespace tokens on the current line
            var hasTag:Boolean = false;    // Is there a {{tag}} on the current line?
            var nonSpace:Boolean = false;  // Is there a non-space char on the current line?

            var start:uint;
            var type:String;
            var value:String;
            var chr:String;
            var token:*;
            var openSection:*;

            // Strips all whitespace tokens array for the current line
            // if there was a {{#tag}} on it and otherwise only space.
            function stripSpace ():void
            {
                if (hasTag && !nonSpace)
                {
                    while (spaces.length)
                    {
                        delete tokens[spaces.pop ()];
                    }
                }
                else spaces = [];

                hasTag = false;
                nonSpace = false;
            }

            while (!scanner.eos ())
            {
                start = scanner.pos;

                // Match any text between tags.
                value = scanner.scanUntil (tagRes[0]);

                if (value)
                {
                    for (var i:uint = 0, len:uint = value.length; i < len; ++i)
                    {
                        chr = value.charAt (i);

                        if (isWhitespace (chr)) spaces.push (tokens.length);
                        else nonSpace = true;

                        tokens.push (['text', chr, start, start + 1]);
                        start += 1;

                        // Check for whitespace on the current line.
                        if (chr == '\n') stripSpace ();
                    }
                }

                // Match the opening tag.
                if (!scanner.scan (tagRes[0])) break;
                hasTag = true;

                // Get the tag type.
                type = scanner.scan (tagRe) || 'name';
                scanner.scan (whiteRe);

                // Get the tag value.
                if (type === '=')
                {
                    value = scanner.scanUntil (eqRe);
                    scanner.scan (eqRe);
                    scanner.scanUntil (tagRes[1]);
                }
                else if (type === '{')
                {
                    value = scanner.scanUntil (new RegExp ('\\s*' + escapeRegExp('}' + tags[1])));
                    scanner.scan (curlyRe);
                    scanner.scanUntil (tagRes[1]);
                    type = '&';
                }
                else value = scanner.scanUntil (tagRes[1]);

                // Match the closing tag.
                if (!scanner.scan (tagRes[1])) throw new Error ('Unclosed tag at ' + scanner.pos);

                token = [type, value, start, scanner.pos];
                tokens.push (token);

                if (type === '#' || type === '^') sections.push(token);
                else if (type === '/')
                {
                    // Check section nesting.
                    if (sections.length === 0) throw new Error('Unopened section "' + value + '" at ' + start);
                    openSection = sections.pop ();
                    if (openSection[1] !== value) throw new Error ('Unclosed section "' + openSection[1] + '" at ' + start);
                }
                else if (type === 'name' || type === '{' || type === '&') nonSpace = true;
                else if (type === '=')
                {
                    // Set the tags for the next time around.
                    tags = value.split (spaceRe);
                    if (tags.length !== 2) throw new Error ('Invalid tags at ' + start + ': ' + tags.join (', '));
                    tagRes = escapeTags (tags);
                }
            }

            // Make sure there are no open sections when we're done.
            openSection = sections.pop ();
            if (openSection) throw new Error('Unclosed section "' + openSection[1] + '" at ' + scanner.pos);

            tokens = squashTokens (tokens);

            return nestTokens (tokens);
        }

        /**
         * Combines the values of consecutive text tokens in the given `tokens` array
         * to a single token.
         *
         * @param tokens
         * @return
         */

        private function squashTokens (tokens:Array):Array
        {
            var squashedTokens:Array = [];
            var token:*;
            var lastToken:*;

            for (var i:uint = 0, len:uint = tokens.length; i < len; ++i)
            {
                token = tokens[i];
                if (token)
                {
                    if (token[0] === 'text' && lastToken && lastToken[0] === 'text')
                    {
                        lastToken[1] += token[1];
                        lastToken[3] = token[3];
                    }
                    else
                    {
                        lastToken = token;
                        squashedTokens.push (token);
                    }
                }
            }

            return squashedTokens;
        }

        /**
         *
         * @param tags
         * @return
         */

        private function escapeTags (tags:Array):Array
        {
            return [
                new RegExp (escapeRegExp (tags[0]) + "\\s*"),
                new RegExp ("\\s*" + escapeRegExp (tags[1]))
            ];
        }

        /**
         *
         * @param string
         * @return
         */

        private function escapeRegExp (string:String):String
        {
            return string.replace (/[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&");
        }

        /**
         *
         * @param string
         * @return
         */

        private function isWhitespace (string:String):Boolean
        {
            return string === "" || string === " ";
        }

        /**
         * Forms the given array of `tokens` into a nested tree structure where
         * tokens that represent a section have two additional items: 1) an array of
         * all tokens that appear in that section and 2) the index in the original
         * template that represents the end of that section.
         *
         * @param tokens
         */

        private function nestTokens (tokens:Array):Array
        {
            var tree:Array = [];
            var collector:Array = tree;
            var sections:Array = [];
            var token:*;

            for (var i:uint = 0, len:uint = tokens.length; i < len; ++i)
            {
                token = tokens[i];
                switch (token[0])
                {
                    case '#':
                    case '^':
                        sections.push (token);
                        collector.push (token);
                        collector = token[4] = [];
                    break;
                    case '/':
                        var section:* = sections.pop ();
                        section[5] = token[2];
                        collector = sections.length > 0 ? sections[sections.length - 1][4] : tree;
                    break;
                    default:
                        collector.push (token);
                }
            }

            return tree;
        }

        /**
         * Low-level function that renders the given `tokens` using the given `writer`
         * and `context`. The `template` string is only needed for templates that use
         * higher-order sections to extract the portion of the original template that
         * was contained in that section.
         *
         * @param tokens
         * @param writer
         * @param context
         * @param template
         */

        private function renderTokens (tokens:Array, writer:Writer, context:Context, template:String):String
        {
            var buffer:String = "";
            var token:*;
            var tokenValue:*;
            var value:*;

            for (var i:uint = 0, len:uint = tokens.length; i < len; ++i)
            {
                token = tokens[i];
                tokenValue = token[1];

                switch (token[0])
                {
                    case '#':
                        value = context.lookup (tokenValue);
                        if (typeof value === 'object')
                        {
                            if (isArray (value))
                            {
                                for (var j:uint = 0, jlen:uint = value.length; j < jlen; ++j)
                                {
                                    buffer += renderTokens (token[4], writer, context.push(value[j]), template);
                                }
                            }
                            else if (value) buffer += renderTokens (token[4], writer, context.push(value), template);
                        }
                        else if (typeof value === 'function')
                        {
                            var text:String = template == null ? null : template.slice (token[3], token[5]);
                            value = value.call (context.view, text, function (template:String):String
                            {
                                return writer.render (template, context);
                            });
                            if (value != null) buffer += value;
                        }
                        else if (value) buffer += renderTokens (token[4], writer, context, template);
                    break;
                    case '^':
                        value = context.lookup (tokenValue);
                        if (!value || (isArray (value) && value.length === 0)) buffer += renderTokens (token[4], writer, context, template);
                    break;
                    case '>':
                        value = writer.getPartial (tokenValue);
                        if (typeof value === 'function') buffer += value (context);
                    break;
                    case '&':
                        value = context.lookup (tokenValue);
                        if (value != null) buffer += value;
                    break;
                    case 'name':
                        value = context.lookup (tokenValue);
                        if (value != null) buffer += escape (value);
                    break;
                    case 'text':
                        buffer += tokenValue;
                    break;
                }
            }

            return buffer;
        }

        /**
         *
         * @param obj
         */

        private function isArray (obj:*):Boolean
        {
            if (typeof (obj) === "object" && typeof (obj.length) === "number") return true;
            return false;
        }

        /**
         *
         * @param template
         * @param view
         * @param partials
         */

        public function render (template:String, view:Object, partials:Object = null):String
        {
            return compile (template)(view, partials);
        }
    }
}
