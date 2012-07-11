Unicode String Scanner
======================

A Unicode-aware implementation of Ruby's `StringScanner`.

|             |                                 |
|:------------|:--------------------------------|
| **Author**  | Tim Morgan                      |
| **Version** | 1.0 (Jul 11, 2012)              |
| **License** | Released under the MIT license. |

About
-----

Did you know that `StringScanner` splits codepoints? Neither did I. This one
doesn't.

**When would I want to use this?** When you want to use `StringScanner` on a
Unicode (UTF-_n_) string.

**When would I _not_ want to use this?** If you're interested in speed. This is
slower than StringScanner because a) it's not written in native C, and b) it's
slower to traverse Unicode strings anyway because characters can have varying
byte sizes.

Installation
------------

Simply add this gem to your project's `Gemfile`:

```` ruby
gem 'unicode_scanner'
````

Usage
-----

The `UnicodeScanner` object responds to exactly the same API as
[StringScanner](http://ruby-doc.org/stdlib-1.9.3/libdoc/strscan/rdoc/StringScanner.html),
with the exception of the following methods:

* `getbyte`
* any obsolete methods

For more information, see the {UnicodeScanner} class documentation.
