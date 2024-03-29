=head1 NAME

JSON::XS - JSON serialising/deserialising, done correctly and fast

=encoding utf-8

JSON::XS - 正しくて高速な JSON シリアライザ/デシリアライザ
           (http://fleur.hio.jp/perldoc/mix/lib/JSON/XS.html)

=head1 SYNOPSIS

 use JSON::XS;

 # exported functions, they croak on error
 # and expect/generate UTF-8

 $utf8_encoded_json_text = encode_json $perl_hash_or_arrayref;
 $perl_hash_or_arrayref  = decode_json $utf8_encoded_json_text;

 # OO-interface

 $coder = JSON::XS->new->ascii->pretty->allow_nonref;
 $pretty_printed_unencoded = $coder->encode ($perl_scalar);
 $perl_scalar = $coder->decode ($unicode_json_text);

 # Note that JSON version 2.0 and above will automatically use JSON::XS
 # if available, at virtually no speed overhead either, so you should
 # be able to just:
 
 use JSON;

 # and do the same things, except that you have a pure-perl fallback now.

=head1 DESCRIPTION

This module converts Perl data structures to JSON and vice versa. Its
primary goal is to be I<correct> and its secondary goal is to be
I<fast>. To reach the latter goal it was written in C.

Beginning with version 2.0 of the JSON module, when both JSON and
JSON::XS are installed, then JSON will fall back on JSON::XS (this can be
overridden) with no overhead due to emulation (by inheriting constructor
and methods). If JSON::XS is not available, it will fall back to the
compatible JSON::PP module as backend, so using JSON instead of JSON::XS
gives you a portable JSON API that can be fast when you need and doesn't
require a C compiler when that is a problem.

As this is the n-th-something JSON module on CPAN, what was the reason
to write yet another JSON module? While it seems there are many JSON
modules, none of them correctly handle all corner cases, and in most cases
their maintainers are unresponsive, gone missing, or not listening to bug
reports for other reasons.

See MAPPING, below, on how JSON::XS maps perl values to JSON values and
vice versa.

=head2 FEATURES

=over 4

=item * correct Unicode handling

This module knows how to handle Unicode, documents how and when it does
so, and even documents what "correct" means.

=item * round-trip integrity

When you serialise a perl data structure using only data types supported
by JSON, the deserialised data structure is identical on the Perl level.
(e.g. the string "2.0" doesn't suddenly become "2" just because it looks
like a number). There minor I<are> exceptions to this, read the MAPPING
section below to learn about those.

=item * strict checking of JSON correctness

There is no guessing, no generating of illegal JSON texts by default,
and only JSON is accepted as input by default (the latter is a security
feature).

=item * fast

Compared to other JSON modules and other serialisers such as Storable,
this module usually compares favourably in terms of speed, too.

=item * simple to use

This module has both a simple functional interface as well as an object
oriented interface interface.

=item * reasonably versatile output formats

You can choose between the most compact guaranteed-single-line format
possible (nice for simple line-based protocols), a pure-ASCII format
(for when your transport is not 8-bit clean, still supports the whole
Unicode range), or a pretty-printed format (for when you want to read that
stuff). Or you can combine those features in whatever way you like.

=back

=cut

package JSON::XS;

no warnings;
use strict;

our $VERSION = '2.232';
our @ISA = qw(Exporter);

our @EXPORT = qw(encode_json decode_json to_json from_json);

sub to_json($) {
   require Carp;
   Carp::croak ("JSON::XS::to_json has been renamed to encode_json, either downgrade to pre-2.0 versions of JSON::XS or rename the call");
}

sub from_json($) {
   require Carp;
   Carp::croak ("JSON::XS::from_json has been renamed to decode_json, either downgrade to pre-2.0 versions of JSON::XS or rename the call");
}

use Exporter;
use XSLoader;

=head1 FUNCTIONAL INTERFACE

The following convenience methods are provided by this module. They are
exported by default:

=over 4

=item $json_text = encode_json $perl_scalar

Converts the given Perl data structure to a UTF-8 encoded, binary string
(that is, the string contains octets only). Croaks on error.

This function call is functionally identical to:

   $json_text = JSON::XS->new->utf8->encode ($perl_scalar)

Except being faster.

=item $perl_scalar = decode_json $json_text

The opposite of C<encode_json>: expects an UTF-8 (binary) string and tries
to parse that as an UTF-8 encoded JSON text, returning the resulting
reference. Croaks on error.

This function call is functionally identical to:

   $perl_scalar = JSON::XS->new->utf8->decode ($json_text)

Except being faster.

=item $is_boolean = JSON::XS::is_bool $scalar

Returns true if the passed scalar represents either JSON::XS::true or
JSON::XS::false, two constants that act like C<1> and C<0>, respectively
and are used to represent JSON C<true> and C<false> values in Perl.

See MAPPING, below, for more information on how JSON values are mapped to
Perl.

=back


=head1 A FEW NOTES ON UNICODE AND PERL

Since this often leads to confusion, here are a few very clear words on
how Unicode works in Perl, modulo bugs.

=over 4

=item 1. Perl strings can store characters with ordinal values > 255.

This enables you to store Unicode characters as single characters in a
Perl string - very natural.

=item 2. Perl does I<not> associate an encoding with your strings.

... until you force it to, e.g. when matching it against a regex, or
printing the scalar to a file, in which case Perl either interprets your
string as locale-encoded text, octets/binary, or as Unicode, depending
on various settings. In no case is an encoding stored together with your
data, it is I<use> that decides encoding, not any magical meta data.

=item 3. The internal utf-8 flag has no meaning with regards to the
encoding of your string.

Just ignore that flag unless you debug a Perl bug, a module written in
XS or want to dive into the internals of perl. Otherwise it will only
confuse you, as, despite the name, it says nothing about how your string
is encoded. You can have Unicode strings with that flag set, with that
flag clear, and you can have binary data with that flag set and that flag
clear. Other possibilities exist, too.

If you didn't know about that flag, just the better, pretend it doesn't
exist.

=item 4. A "Unicode String" is simply a string where each character can be
validly interpreted as a Unicode code point.

If you have UTF-8 encoded data, it is no longer a Unicode string, but a
Unicode string encoded in UTF-8, giving you a binary string.

=item 5. A string containing "high" (> 255) character values is I<not> a UTF-8 string.

It's a fact. Learn to live with it.

=back

I hope this helps :)


=head1 OBJECT-ORIENTED INTERFACE

The object oriented interface lets you configure your own encoding or
decoding style, within the limits of supported formats.

=over 4

=item $json = new JSON::XS

Creates a new JSON::XS object that can be used to de/encode JSON
strings. All boolean flags described below are by default I<disabled>.

The mutators for flags all return the JSON object again and thus calls can
be chained:

   my $json = JSON::XS->new->utf8->space_after->encode ({a => [1,2]})
   => {"a": [1, 2]}

=item $json = $json->ascii ([$enable])

=item $enabled = $json->get_ascii

If C<$enable> is true (or missing), then the C<encode> method will not
generate characters outside the code range C<0..127> (which is ASCII). Any
Unicode characters outside that range will be escaped using either a
single \uXXXX (BMP characters) or a double \uHHHH\uLLLLL escape sequence,
as per RFC4627. The resulting encoded JSON text can be treated as a native
Unicode string, an ascii-encoded, latin1-encoded or UTF-8 encoded string,
or any other superset of ASCII.

If C<$enable> is false, then the C<encode> method will not escape Unicode
characters unless required by the JSON syntax or other flags. This results
in a faster and more compact format.

See also the section I<ENCODING/CODESET FLAG NOTES> later in this
document.

The main use for this flag is to produce JSON texts that can be
transmitted over a 7-bit channel, as the encoded JSON texts will not
contain any 8 bit characters.

  JSON::XS->new->ascii (1)->encode ([chr 0x10401])
  => ["\ud801\udc01"]

=item $json = $json->latin1 ([$enable])

=item $enabled = $json->get_latin1

If C<$enable> is true (or missing), then the C<encode> method will encode
the resulting JSON text as latin1 (or iso-8859-1), escaping any characters
outside the code range C<0..255>. The resulting string can be treated as a
latin1-encoded JSON text or a native Unicode string. The C<decode> method
will not be affected in any way by this flag, as C<decode> by default
expects Unicode, which is a strict superset of latin1.

If C<$enable> is false, then the C<encode> method will not escape Unicode
characters unless required by the JSON syntax or other flags.

See also the section I<ENCODING/CODESET FLAG NOTES> later in this
document.

The main use for this flag is efficiently encoding binary data as JSON
text, as most octets will not be escaped, resulting in a smaller encoded
size. The disadvantage is that the resulting JSON text is encoded
in latin1 (and must correctly be treated as such when storing and
transferring), a rare encoding for JSON. It is therefore most useful when
you want to store data structures known to contain binary data efficiently
in files or databases, not when talking to other JSON encoders/decoders.

  JSON::XS->new->latin1->encode (["\x{89}\x{abc}"]
  => ["\x{89}\\u0abc"]    # (perl syntax, U+abc escaped, U+89 not)

=item $json = $json->utf8 ([$enable])

=item $enabled = $json->get_utf8

If C<$enable> is true (or missing), then the C<encode> method will encode
the JSON result into UTF-8, as required by many protocols, while the
C<decode> method expects to be handled an UTF-8-encoded string.  Please
note that UTF-8-encoded strings do not contain any characters outside the
range C<0..255>, they are thus useful for bytewise/binary I/O. In future
versions, enabling this option might enable autodetection of the UTF-16
and UTF-32 encoding families, as described in RFC4627.

If C<$enable> is false, then the C<encode> method will return the JSON
string as a (non-encoded) Unicode string, while C<decode> expects thus a
Unicode string.  Any decoding or encoding (e.g. to UTF-8 or UTF-16) needs
to be done yourself, e.g. using the Encode module.

See also the section I<ENCODING/CODESET FLAG NOTES> later in this
document.

Example, output UTF-16BE-encoded JSON:

  use Encode;
  $jsontext = encode "UTF-16BE", JSON::XS->new->encode ($object);

Example, decode UTF-32LE-encoded JSON:

  use Encode;
  $object = JSON::XS->new->decode (decode "UTF-32LE", $jsontext);

=item $json = $json->pretty ([$enable])

This enables (or disables) all of the C<indent>, C<space_before> and
C<space_after> (and in the future possibly more) flags in one call to
generate the most readable (or most compact) form possible.

Example, pretty-print some simple structure:

   my $json = JSON::XS->new->pretty(1)->encode ({a => [1,2]})
   =>
   {
      "a" : [
         1,
         2
      ]
   }

=item $json = $json->indent ([$enable])

=item $enabled = $json->get_indent

If C<$enable> is true (or missing), then the C<encode> method will use a multiline
format as output, putting every array member or object/hash key-value pair
into its own line, indenting them properly.

If C<$enable> is false, no newlines or indenting will be produced, and the
resulting JSON text is guaranteed not to contain any C<newlines>.

This setting has no effect when decoding JSON texts.

=item $json = $json->space_before ([$enable])

=item $enabled = $json->get_space_before

If C<$enable> is true (or missing), then the C<encode> method will add an extra
optional space before the C<:> separating keys from values in JSON objects.

If C<$enable> is false, then the C<encode> method will not add any extra
space at those places.

This setting has no effect when decoding JSON texts. You will also
most likely combine this setting with C<space_after>.

Example, space_before enabled, space_after and indent disabled:

   {"key" :"value"}

=item $json = $json->space_after ([$enable])

=item $enabled = $json->get_space_after

If C<$enable> is true (or missing), then the C<encode> method will add an extra
optional space after the C<:> separating keys from values in JSON objects
and extra whitespace after the C<,> separating key-value pairs and array
members.

If C<$enable> is false, then the C<encode> method will not add any extra
space at those places.

This setting has no effect when decoding JSON texts.

Example, space_before and indent disabled, space_after enabled:

   {"key": "value"}

=item $json = $json->relaxed ([$enable])

=item $enabled = $json->get_relaxed

If C<$enable> is true (or missing), then C<decode> will accept some
extensions to normal JSON syntax (see below). C<encode> will not be
affected in anyway. I<Be aware that this option makes you accept invalid
JSON texts as if they were valid!>. I suggest only to use this option to
parse application-specific files written by humans (configuration files,
resource files etc.)

If C<$enable> is false (the default), then C<decode> will only accept
valid JSON texts.

Currently accepted extensions are:

=over 4

=item * list items can have an end-comma

JSON I<separates> array elements and key-value pairs with commas. This
can be annoying if you write JSON texts manually and want to be able to
quickly append elements, so this extension accepts comma at the end of
such items not just between them:

   [
      1,
      2, <- this comma not normally allowed
   ]
   {
      "k1": "v1",
      "k2": "v2", <- this comma not normally allowed
   }

=item * shell-style '#'-comments

Whenever JSON allows whitespace, shell-style comments are additionally
allowed. They are terminated by the first carriage-return or line-feed
character, after which more white-space and comments are allowed.

  [
     1, # this comment not allowed in JSON
        # neither this one...
  ]

=back

=item $json = $json->canonical ([$enable])

=item $enabled = $json->get_canonical

If C<$enable> is true (or missing), then the C<encode> method will output JSON objects
by sorting their keys. This is adding a comparatively high overhead.

If C<$enable> is false, then the C<encode> method will output key-value
pairs in the order Perl stores them (which will likely change between runs
of the same script).

This option is useful if you want the same data structure to be encoded as
the same JSON text (given the same overall settings). If it is disabled,
the same hash might be encoded differently even if contains the same data,
as key-value pairs have no inherent ordering in Perl.

This setting has no effect when decoding JSON texts.

=item $json = $json->allow_nonref ([$enable])

=item $enabled = $json->get_allow_nonref

If C<$enable> is true (or missing), then the C<encode> method can convert a
non-reference into its corresponding string, number or null JSON value,
which is an extension to RFC4627. Likewise, C<decode> will accept those JSON
values instead of croaking.

If C<$enable> is false, then the C<encode> method will croak if it isn't
passed an arrayref or hashref, as JSON texts must either be an object
or array. Likewise, C<decode> will croak if given something that is not a
JSON object or array.

Example, encode a Perl scalar as JSON value with enabled C<allow_nonref>,
resulting in an invalid JSON text:

   JSON::XS->new->allow_nonref->encode ("Hello, World!")
   => "Hello, World!"

=item $json = $json->allow_unknown ([$enable])

=item $enabled = $json->get_allow_unknown

If C<$enable> is true (or missing), then C<encode> will I<not> throw an
exception when it encounters values it cannot represent in JSON (for
example, filehandles) but instead will encode a JSON C<null> value. Note
that blessed objects are not included here and are handled separately by
c<allow_nonref>.

If C<$enable> is false (the default), then C<encode> will throw an
exception when it encounters anything it cannot encode as JSON.

This option does not affect C<decode> in any way, and it is recommended to
leave it off unless you know your communications partner.

=item $json = $json->allow_blessed ([$enable])

=item $enabled = $json->get_allow_blessed

If C<$enable> is true (or missing), then the C<encode> method will not
barf when it encounters a blessed reference. Instead, the value of the
B<convert_blessed> option will decide whether C<null> (C<convert_blessed>
disabled or no C<TO_JSON> method found) or a representation of the
object (C<convert_blessed> enabled and C<TO_JSON> method found) is being
encoded. Has no effect on C<decode>.

If C<$enable> is false (the default), then C<encode> will throw an
exception when it encounters a blessed object.

=item $json = $json->convert_blessed ([$enable])

=item $enabled = $json->get_convert_blessed

If C<$enable> is true (or missing), then C<encode>, upon encountering a
blessed object, will check for the availability of the C<TO_JSON> method
on the object's class. If found, it will be called in scalar context
and the resulting scalar will be encoded instead of the object. If no
C<TO_JSON> method is found, the value of C<allow_blessed> will decide what
to do.

The C<TO_JSON> method may safely call die if it wants. If C<TO_JSON>
returns other blessed objects, those will be handled in the same
way. C<TO_JSON> must take care of not causing an endless recursion cycle
(== crash) in this case. The name of C<TO_JSON> was chosen because other
methods called by the Perl core (== not by the user of the object) are
usually in upper case letters and to avoid collisions with any C<to_json>
function or method.

This setting does not yet influence C<decode> in any way, but in the
future, global hooks might get installed that influence C<decode> and are
enabled by this setting.

If C<$enable> is false, then the C<allow_blessed> setting will decide what
to do when a blessed object is found.

=item $json = $json->filter_json_object ([$coderef->($hashref)])

When C<$coderef> is specified, it will be called from C<decode> each
time it decodes a JSON object. The only argument is a reference to the
newly-created hash. If the code references returns a single scalar (which
need not be a reference), this value (i.e. a copy of that scalar to avoid
aliasing) is inserted into the deserialised data structure. If it returns
an empty list (NOTE: I<not> C<undef>, which is a valid scalar), the
original deserialised hash will be inserted. This setting can slow down
decoding considerably.

When C<$coderef> is omitted or undefined, any existing callback will
be removed and C<decode> will not change the deserialised hash in any
way.

Example, convert all JSON objects into the integer 5:

   my $js = JSON::XS->new->filter_json_object (sub { 5 });
   # returns [5]
   $js->decode ('[{}]')
   # throw an exception because allow_nonref is not enabled
   # so a lone 5 is not allowed.
   $js->decode ('{"a":1, "b":2}');

=item $json = $json->filter_json_single_key_object ($key [=> $coderef->($value)])

Works remotely similar to C<filter_json_object>, but is only called for
JSON objects having a single key named C<$key>.

This C<$coderef> is called before the one specified via
C<filter_json_object>, if any. It gets passed the single value in the JSON
object. If it returns a single value, it will be inserted into the data
structure. If it returns nothing (not even C<undef> but the empty list),
the callback from C<filter_json_object> will be called next, as if no
single-key callback were specified.

If C<$coderef> is omitted or undefined, the corresponding callback will be
disabled. There can only ever be one callback for a given key.

As this callback gets called less often then the C<filter_json_object>
one, decoding speed will not usually suffer as much. Therefore, single-key
objects make excellent targets to serialise Perl objects into, especially
as single-key JSON objects are as close to the type-tagged value concept
as JSON gets (it's basically an ID/VALUE tuple). Of course, JSON does not
support this in any way, so you need to make sure your data never looks
like a serialised Perl hash.

Typical names for the single object key are C<__class_whatever__>, or
C<$__dollars_are_rarely_used__$> or C<}ugly_brace_placement>, or even
things like C<__class_md5sum(classname)__>, to reduce the risk of clashing
with real hashes.

Example, decode JSON objects of the form C<< { "__widget__" => <id> } >>
into the corresponding C<< $WIDGET{<id>} >> object:

   # return whatever is in $WIDGET{5}:
   JSON::XS
      ->new
      ->filter_json_single_key_object (__widget__ => sub {
            $WIDGET{ $_[0] }
         })
      ->decode ('{"__widget__": 5')

   # this can be used with a TO_JSON method in some "widget" class
   # for serialisation to json:
   sub WidgetBase::TO_JSON {
      my ($self) = @_;

      unless ($self->{id}) {
         $self->{id} = ..get..some..id..;
         $WIDGET{$self->{id}} = $self;
      }

      { __widget__ => $self->{id} }
   }

=item $json = $json->shrink ([$enable])

=item $enabled = $json->get_shrink

Perl usually over-allocates memory a bit when allocating space for
strings. This flag optionally resizes strings generated by either
C<encode> or C<decode> to their minimum size possible. This can save
memory when your JSON texts are either very very long or you have many
short strings. It will also try to downgrade any strings to octet-form
if possible: perl stores strings internally either in an encoding called
UTF-X or in octet-form. The latter cannot store everything but uses less
space in general (and some buggy Perl or C code might even rely on that
internal representation being used).

The actual definition of what shrink does might change in future versions,
but it will always try to save space at the expense of time.

If C<$enable> is true (or missing), the string returned by C<encode> will
be shrunk-to-fit, while all strings generated by C<decode> will also be
shrunk-to-fit.

If C<$enable> is false, then the normal perl allocation algorithms are used.
If you work with your data, then this is likely to be faster.

In the future, this setting might control other things, such as converting
strings that look like integers or floats into integers or floats
internally (there is no difference on the Perl level), saving space.

=item $json = $json->max_depth ([$maximum_nesting_depth])

=item $max_depth = $json->get_max_depth

Sets the maximum nesting level (default C<512>) accepted while encoding
or decoding. If a higher nesting level is detected in JSON text or a Perl
data structure, then the encoder and decoder will stop and croak at that
point.

Nesting level is defined by number of hash- or arrayrefs that the encoder
needs to traverse to reach a given point or the number of C<{> or C<[>
characters without their matching closing parenthesis crossed to reach a
given character in a string.

Setting the maximum depth to one disallows any nesting, so that ensures
that the object is only a single hash/object or array.

If no argument is given, the highest possible setting will be used, which
is rarely useful.

Note that nesting is implemented by recursion in C. The default value has
been chosen to be as large as typical operating systems allow without
crashing.

See SECURITY CONSIDERATIONS, below, for more info on why this is useful.

=item $json = $json->max_size ([$maximum_string_size])

=item $max_size = $json->get_max_size

Set the maximum length a JSON text may have (in bytes) where decoding is
being attempted. The default is C<0>, meaning no limit. When C<decode>
is called on a string that is longer then this many bytes, it will not
attempt to decode the string but throw an exception. This setting has no
effect on C<encode> (yet).

If no argument is given, the limit check will be deactivated (same as when
C<0> is specified).

See SECURITY CONSIDERATIONS, below, for more info on why this is useful.

=item $json_text = $json->encode ($perl_scalar)

Converts the given Perl data structure (a simple scalar or a reference
to a hash or array) to its JSON representation. Simple scalars will be
converted into JSON string or number sequences, while references to arrays
become JSON arrays and references to hashes become JSON objects. Undefined
Perl values (e.g. C<undef>) become JSON C<null> values. Neither C<true>
nor C<false> values will be generated.

=item $perl_scalar = $json->decode ($json_text)

The opposite of C<encode>: expects a JSON text and tries to parse it,
returning the resulting simple scalar or reference. Croaks on error.

JSON numbers and strings become simple Perl scalars. JSON arrays become
Perl arrayrefs and JSON objects become Perl hashrefs. C<true> becomes
C<1>, C<false> becomes C<0> and C<null> becomes C<undef>.

=item ($perl_scalar, $characters) = $json->decode_prefix ($json_text)

This works like the C<decode> method, but instead of raising an exception
when there is trailing garbage after the first JSON object, it will
silently stop parsing there and return the number of characters consumed
so far.

This is useful if your JSON texts are not delimited by an outer protocol
(which is not the brightest thing to do in the first place) and you need
to know where the JSON text ends.

   JSON::XS->new->decode_prefix ("[1] the tail")
   => ([], 3)

=back


=head1 INCREMENTAL PARSING

In some cases, there is the need for incremental parsing of JSON
texts. While this module always has to keep both JSON text and resulting
Perl data structure in memory at one time, it does allow you to parse a
JSON stream incrementally. It does so by accumulating text until it has
a full JSON object, which it then can decode. This process is similar to
using C<decode_prefix> to see if a full JSON object is available, but
is much more efficient (and can be implemented with a minimum of method
calls).

JSON::XS will only attempt to parse the JSON text once it is sure it
has enough text to get a decisive result, using a very simple but
truly incremental parser. This means that it sometimes won't stop as
early as the full parser, for example, it doesn't detect parenthese
mismatches. The only thing it guarantees is that it starts decoding as
soon as a syntactically valid JSON text has been seen. This means you need
to set resource limits (e.g. C<max_size>) to ensure the parser will stop
parsing in the presence if syntax errors.

The following methods implement this incremental parser.

=over 4

=item [void, scalar or list context] = $json->incr_parse ([$string])

This is the central parsing function. It can both append new text and
extract objects from the stream accumulated so far (both of these
functions are optional).

If C<$string> is given, then this string is appended to the already
existing JSON fragment stored in the C<$json> object.

After that, if the function is called in void context, it will simply
return without doing anything further. This can be used to add more text
in as many chunks as you want.

If the method is called in scalar context, then it will try to extract
exactly I<one> JSON object. If that is successful, it will return this
object, otherwise it will return C<undef>. If there is a parse error,
this method will croak just as C<decode> would do (one can then use
C<incr_skip> to skip the errornous part). This is the most common way of
using the method.

And finally, in list context, it will try to extract as many objects
from the stream as it can find and return them, or the empty list
otherwise. For this to work, there must be no separators between the JSON
objects or arrays, instead they must be concatenated back-to-back. If
an error occurs, an exception will be raised as in the scalar context
case. Note that in this case, any previously-parsed JSON texts will be
lost.

=item $lvalue_string = $json->incr_text

This method returns the currently stored JSON fragment as an lvalue, that
is, you can manipulate it. This I<only> works when a preceding call to
C<incr_parse> in I<scalar context> successfully returned an object. Under
all other circumstances you must not call this function (I mean it.
although in simple tests it might actually work, it I<will> fail under
real world conditions). As a special exception, you can also call this
method before having parsed anything.

This function is useful in two cases: a) finding the trailing text after a
JSON object or b) parsing multiple JSON objects separated by non-JSON text
(such as commas).

=item $json->incr_skip

This will reset the state of the incremental parser and will remove
the parsed text from the input buffer so far. This is useful after
C<incr_parse> died, in which case the input buffer and incremental parser
state is left unchanged, to skip the text parsed so far and to reset the
parse state.

The difference to C<incr_reset> is that only text until the parse error
occured is removed.

=item $json->incr_reset

This completely resets the incremental parser, that is, after this call,
it will be as if the parser had never parsed anything.

This is useful if you want to repeatedly parse JSON objects and want to
ignore any trailing data, which means you have to reset the parser after
each successful decode.

=back

=head2 LIMITATIONS

All options that affect decoding are supported, except
C<allow_nonref>. The reason for this is that it cannot be made to
work sensibly: JSON objects and arrays are self-delimited, i.e. you can concatenate
them back to back and still decode them perfectly. This does not hold true
for JSON numbers, however.

For example, is the string C<1> a single JSON number, or is it simply the
start of C<12>? Or is C<12> a single JSON number, or the concatenation
of C<1> and C<2>? In neither case you can tell, and this is why JSON::XS
takes the conservative route and disallows this case.

=head2 EXAMPLES

Some examples will make all this clearer. First, a simple example that
works similarly to C<decode_prefix>: We want to decode the JSON object at
the start of a string and identify the portion after the JSON object:

   my $text = "[1,2,3] hello";

   my $json = new JSON::XS;

   my $obj = $json->incr_parse ($text)
      or die "expected JSON object or array at beginning of string";

   my $tail = $json->incr_text;
   # $tail now contains " hello"

Easy, isn't it?

Now for a more complicated example: Imagine a hypothetical protocol where
you read some requests from a TCP stream, and each request is a JSON
array, without any separation between them (in fact, it is often useful to
use newlines as "separators", as these get interpreted as whitespace at
the start of the JSON text, which makes it possible to test said protocol
with C<telnet>...).

Here is how you'd do it (it is trivial to write this in an event-based
manner):

   my $json = new JSON::XS;

   # read some data from the socket
   while (sysread $socket, my $buf, 4096) {

      # split and decode as many requests as possible
      for my $request ($json->incr_parse ($buf)) {
         # act on the $request
      }
   }

Another complicated example: Assume you have a string with JSON objects
or arrays, all separated by (optional) comma characters (e.g. C<[1],[2],
[3]>). To parse them, we have to skip the commas between the JSON texts,
and here is where the lvalue-ness of C<incr_text> comes in useful:

   my $text = "[1],[2], [3]";
   my $json = new JSON::XS;

   # void context, so no parsing done
   $json->incr_parse ($text);

   # now extract as many objects as possible. note the
   # use of scalar context so incr_text can be called.
   while (my $obj = $json->incr_parse) {
      # do something with $obj

      # now skip the optional comma
      $json->incr_text =~ s/^ \s* , //x;
   }

Now lets go for a very complex example: Assume that you have a gigantic
JSON array-of-objects, many gigabytes in size, and you want to parse it,
but you cannot load it into memory fully (this has actually happened in
the real world :).

Well, you lost, you have to implement your own JSON parser. But JSON::XS
can still help you: You implement a (very simple) array parser and let
JSON decode the array elements, which are all full JSON objects on their
own (this wouldn't work if the array elements could be JSON numbers, for
example):

   my $json = new JSON::XS;

   # open the monster
   open my $fh, "<bigfile.json"
      or die "bigfile: $!";

   # first parse the initial "["
   for (;;) {
      sysread $fh, my $buf, 65536
         or die "read error: $!";
      $json->incr_parse ($buf); # void context, so no parsing

      # Exit the loop once we found and removed(!) the initial "[".
      # In essence, we are (ab-)using the $json object as a simple scalar
      # we append data to.
      last if $json->incr_text =~ s/^ \s* \[ //x;
   }

   # now we have the skipped the initial "[", so continue
   # parsing all the elements.
   for (;;) {
      # in this loop we read data until we got a single JSON object
      for (;;) {
         if (my $obj = $json->incr_parse) {
            # do something with $obj
            last;
         }

         # add more data
         sysread $fh, my $buf, 65536
            or die "read error: $!";
         $json->incr_parse ($buf); # void context, so no parsing
      }

      # in this loop we read data until we either found and parsed the
      # separating "," between elements, or the final "]"
      for (;;) {
         # first skip whitespace
         $json->incr_text =~ s/^\s*//;

         # if we find "]", we are done
         if ($json->incr_text =~ s/^\]//) {
            print "finished.\n";
            exit;
         }

         # if we find ",", we can continue with the next element
         if ($json->incr_text =~ s/^,//) {
            last;
         }

         # if we find anything else, we have a parse error!
         if (length $json->incr_text) {
            die "parse error near ", $json->incr_text;
         }

         # else add more data
         sysread $fh, my $buf, 65536
            or die "read error: $!";
         $json->incr_parse ($buf); # void context, so no parsing
      }

This is a complex example, but most of the complexity comes from the fact
that we are trying to be correct (bear with me if I am wrong, I never ran
the above example :).



=head1 MAPPING

This section describes how JSON::XS maps Perl values to JSON values and
vice versa. These mappings are designed to "do the right thing" in most
circumstances automatically, preserving round-tripping characteristics
(what you put in comes out as something equivalent).

For the more enlightened: note that in the following descriptions,
lowercase I<perl> refers to the Perl interpreter, while uppercase I<Perl>
refers to the abstract Perl language itself.


=head2 JSON -> PERL

=over 4

=item object

A JSON object becomes a reference to a hash in Perl. No ordering of object
keys is preserved (JSON does not preserve object key ordering itself).

=item array

A JSON array becomes a reference to an array in Perl.

=item string

A JSON string becomes a string scalar in Perl - Unicode codepoints in JSON
are represented by the same codepoints in the Perl string, so no manual
decoding is necessary.

=item number

A JSON number becomes either an integer, numeric (floating point) or
string scalar in perl, depending on its range and any fractional parts. On
the Perl level, there is no difference between those as Perl handles all
the conversion details, but an integer may take slightly less memory and
might represent more values exactly than floating point numbers.

If the number consists of digits only, JSON::XS will try to represent
it as an integer value. If that fails, it will try to represent it as
a numeric (floating point) value if that is possible without loss of
precision. Otherwise it will preserve the number as a string value (in
which case you lose roundtripping ability, as the JSON number will be
re-encoded toa JSON string).

Numbers containing a fractional or exponential part will always be
represented as numeric (floating point) values, possibly at a loss of
precision (in which case you might lose perfect roundtripping ability, but
the JSON number will still be re-encoded as a JSON number).

=item true, false

These JSON atoms become C<JSON::XS::true> and C<JSON::XS::false>,
respectively. They are overloaded to act almost exactly like the numbers
C<1> and C<0>. You can check whether a scalar is a JSON boolean by using
the C<JSON::XS::is_bool> function.

=item null

A JSON null atom becomes C<undef> in Perl.

=back


=head2 PERL -> JSON

The mapping from Perl to JSON is slightly more difficult, as Perl is a
truly typeless language, so we can only guess which JSON type is meant by
a Perl value.

=over 4

=item hash references

Perl hash references become JSON objects. As there is no inherent ordering
in hash keys (or JSON objects), they will usually be encoded in a
pseudo-random order that can change between runs of the same program but
stays generally the same within a single run of a program. JSON::XS can
optionally sort the hash keys (determined by the I<canonical> flag), so
the same datastructure will serialise to the same JSON text (given same
settings and version of JSON::XS), but this incurs a runtime overhead
and is only rarely useful, e.g. when you want to compare some JSON text
against another for equality.

=item array references

Perl array references become JSON arrays.

=item other references

Other unblessed references are generally not allowed and will cause an
exception to be thrown, except for references to the integers C<0> and
C<1>, which get turned into C<false> and C<true> atoms in JSON. You can
also use C<JSON::XS::false> and C<JSON::XS::true> to improve readability.

   encode_json [\0, JSON::XS::true]      # yields [false,true]

=item JSON::XS::true, JSON::XS::false

These special values become JSON true and JSON false values,
respectively. You can also use C<\1> and C<\0> directly if you want.

=item blessed objects

Blessed objects are not directly representable in JSON. See the
C<allow_blessed> and C<convert_blessed> methods on various options on
how to deal with this: basically, you can choose between throwing an
exception, encoding the reference as if it weren't blessed, or provide
your own serialiser method.

=item simple scalars

Simple Perl scalars (any scalar that is not a reference) are the most
difficult objects to encode: JSON::XS will encode undefined scalars as
JSON C<null> values, scalars that have last been used in a string context
before encoding as JSON strings, and anything else as number value:

   # dump as number
   encode_json [2]                      # yields [2]
   encode_json [-3.0e17]                # yields [-3e+17]
   my $value = 5; encode_json [$value]  # yields [5]

   # used as string, so dump as string
   print $value;
   encode_json [$value]                 # yields ["5"]

   # undef becomes null
   encode_json [undef]                  # yields [null]

You can force the type to be a JSON string by stringifying it:

   my $x = 3.1; # some variable containing a number
   "$x";        # stringified
   $x .= "";    # another, more awkward way to stringify
   print $x;    # perl does it for you, too, quite often

You can force the type to be a JSON number by numifying it:

   my $x = "3"; # some variable containing a string
   $x += 0;     # numify it, ensuring it will be dumped as a number
   $x *= 1;     # same thing, the choice is yours.

You can not currently force the type in other, less obscure, ways. Tell me
if you need this capability (but don't forget to explain why it's needed
:).

=back


=head1 ENCODING/CODESET FLAG NOTES

The interested reader might have seen a number of flags that signify
encodings or codesets - C<utf8>, C<latin1> and C<ascii>. There seems to be
some confusion on what these do, so here is a short comparison:

C<utf8> controls whether the JSON text created by C<encode> (and expected
by C<decode>) is UTF-8 encoded or not, while C<latin1> and C<ascii> only
control whether C<encode> escapes character values outside their respective
codeset range. Neither of these flags conflict with each other, although
some combinations make less sense than others.

Care has been taken to make all flags symmetrical with respect to
C<encode> and C<decode>, that is, texts encoded with any combination of
these flag values will be correctly decoded when the same flags are used
- in general, if you use different flag settings while encoding vs. when
decoding you likely have a bug somewhere.

Below comes a verbose discussion of these flags. Note that a "codeset" is
simply an abstract set of character-codepoint pairs, while an encoding
takes those codepoint numbers and I<encodes> them, in our case into
octets. Unicode is (among other things) a codeset, UTF-8 is an encoding,
and ISO-8859-1 (= latin 1) and ASCII are both codesets I<and> encodings at
the same time, which can be confusing.

=over 4

=item C<utf8> flag disabled

When C<utf8> is disabled (the default), then C<encode>/C<decode> generate
and expect Unicode strings, that is, characters with high ordinal Unicode
values (> 255) will be encoded as such characters, and likewise such
characters are decoded as-is, no canges to them will be done, except
"(re-)interpreting" them as Unicode codepoints or Unicode characters,
respectively (to Perl, these are the same thing in strings unless you do
funny/weird/dumb stuff).

This is useful when you want to do the encoding yourself (e.g. when you
want to have UTF-16 encoded JSON texts) or when some other layer does
the encoding for you (for example, when printing to a terminal using a
filehandle that transparently encodes to UTF-8 you certainly do NOT want
to UTF-8 encode your data first and have Perl encode it another time).

=item C<utf8> flag enabled

If the C<utf8>-flag is enabled, C<encode>/C<decode> will encode all
characters using the corresponding UTF-8 multi-byte sequence, and will
expect your input strings to be encoded as UTF-8, that is, no "character"
of the input string must have any value > 255, as UTF-8 does not allow
that.

The C<utf8> flag therefore switches between two modes: disabled means you
will get a Unicode string in Perl, enabled means you get an UTF-8 encoded
octet/binary string in Perl.

=item C<latin1> or C<ascii> flags enabled

With C<latin1> (or C<ascii>) enabled, C<encode> will escape characters
with ordinal values > 255 (> 127 with C<ascii>) and encode the remaining
characters as specified by the C<utf8> flag.

If C<utf8> is disabled, then the result is also correctly encoded in those
character sets (as both are proper subsets of Unicode, meaning that a
Unicode string with all character values < 256 is the same thing as a
ISO-8859-1 string, and a Unicode string with all character values < 128 is
the same thing as an ASCII string in Perl).

If C<utf8> is enabled, you still get a correct UTF-8-encoded string,
regardless of these flags, just some more characters will be escaped using
C<\uXXXX> then before.

Note that ISO-8859-1-I<encoded> strings are not compatible with UTF-8
encoding, while ASCII-encoded strings are. That is because the ISO-8859-1
encoding is NOT a subset of UTF-8 (despite the ISO-8859-1 I<codeset> being
a subset of Unicode), while ASCII is.

Surprisingly, C<decode> will ignore these flags and so treat all input
values as governed by the C<utf8> flag. If it is disabled, this allows you
to decode ISO-8859-1- and ASCII-encoded strings, as both strict subsets of
Unicode. If it is enabled, you can correctly decode UTF-8 encoded strings.

So neither C<latin1> nor C<ascii> are incompatible with the C<utf8> flag -
they only govern when the JSON output engine escapes a character or not.

The main use for C<latin1> is to relatively efficiently store binary data
as JSON, at the expense of breaking compatibility with most JSON decoders.

The main use for C<ascii> is to force the output to not contain characters
with values > 127, which means you can interpret the resulting string
as UTF-8, ISO-8859-1, ASCII, KOI8-R or most about any character set and
8-bit-encoding, and still get the same data structure back. This is useful
when your channel for JSON transfer is not 8-bit clean or the encoding
might be mangled in between (e.g. in mail), and works because ASCII is a
proper subset of most 8-bit and multibyte encodings in use in the world.

=back


=head2 JSON and ECMAscript

JSON syntax is based on how literals are represented in javascript (the
not-standardised predecessor of ECMAscript) which is presumably why it is
called "JavaScript Object Notation".

However, JSON is not a subset (and also not a superset of course) of
ECMAscript (the standard) or javascript (whatever browsers actually
implement).

If you want to use javascript's C<eval> function to "parse" JSON, you
might run into parse errors for valid JSON texts, or the resulting data
structure might not be queryable:

One of the problems is that U+2028 and U+2029 are valid characters inside
JSON strings, but are not allowed in ECMAscript string literals, so the
following Perl fragment will not output something that can be guaranteed
to be parsable by javascript's C<eval>:

   use JSON::XS;

   print encode_json [chr 0x2028];

The right fix for this is to use a proper JSON parser in your javascript
programs, and not rely on C<eval> (see for example Douglas Crockford's
F<json2.js> parser).

If this is not an option, you can, as a stop-gap measure, simply encode to
ASCII-only JSON:

   use JSON::XS;

   print JSON::XS->new->ascii->encode ([chr 0x2028]);

Note that this will enlarge the resulting JSON text quite a bit if you
have many non-ASCII characters. You might be tempted to run some regexes
to only escape U+2028 and U+2029, e.g.:

   # DO NOT USE THIS!
   my $json = JSON::XS->new->utf8->encode ([chr 0x2028]);
   $json =~ s/\xe2\x80\xa8/\\u2028/g; # escape U+2028
   $json =~ s/\xe2\x80\xa9/\\u2029/g; # escape U+2029
   print $json;

Note that I<this is a bad idea>: the above only works for U+2028 and
U+2029 and thus only for fully ECMAscript-compliant parsers. Many existing
javascript implementations, however, have issues with other characters as
well - using C<eval> naively simply I<will> cause problems.

Another problem is that some javascript implementations reserve
some property names for their own purposes (which probably makes
them non-ECMAscript-compliant). For example, Iceweasel reserves the
C<__proto__> property name for it's own purposes.

If that is a problem, you could parse try to filter the resulting JSON
output for these property strings, e.g.:

   $json =~ s/"__proto__"\s*:/"__proto__renamed":/g;

This works because C<__proto__> is not valid outside of strings, so every
occurence of C<"__proto__"\s*:> must be a string used as property name.

If you know of other incompatibilities, please let me know.


=head2 JSON and YAML

You often hear that JSON is a subset of YAML. This is, however, a mass
hysteria(*) and very far from the truth (as of the time of this writing),
so let me state it clearly: I<in general, there is no way to configure
JSON::XS to output a data structure as valid YAML> that works in all
cases.

If you really must use JSON::XS to generate YAML, you should use this
algorithm (subject to change in future versions):

   my $to_yaml = JSON::XS->new->utf8->space_after (1);
   my $yaml = $to_yaml->encode ($ref) . "\n";

This will I<usually> generate JSON texts that also parse as valid
YAML. Please note that YAML has hardcoded limits on (simple) object key
lengths that JSON doesn't have and also has different and incompatible
unicode handling, so you should make sure that your hash keys are
noticeably shorter than the 1024 "stream characters" YAML allows and that
you do not have characters with codepoint values outside the Unicode BMP
(basic multilingual page). YAML also does not allow C<\/> sequences in
strings (which JSON::XS does not I<currently> generate, but other JSON
generators might).

There might be other incompatibilities that I am not aware of (or the YAML
specification has been changed yet again - it does so quite often). In
general you should not try to generate YAML with a JSON generator or vice
versa, or try to parse JSON with a YAML parser or vice versa: chances are
high that you will run into severe interoperability problems when you
least expect it.

=over 4

=item (*)

I have been pressured multiple times by Brian Ingerson (one of the
authors of the YAML specification) to remove this paragraph, despite him
acknowledging that the actual incompatibilities exist. As I was personally
bitten by this "JSON is YAML" lie, I refused and said I will continue to
educate people about these issues, so others do not run into the same
problem again and again. After this, Brian called me a (quote)I<complete
and worthless idiot>(unquote).

In my opinion, instead of pressuring and insulting people who actually
clarify issues with YAML and the wrong statements of some of its
proponents, I would kindly suggest reading the JSON spec (which is not
that difficult or long) and finally make YAML compatible to it, and
educating users about the changes, instead of spreading lies about the
real compatibility for many I<years> and trying to silence people who
point out that it isn't true.

=back


=head2 SPEED

It seems that JSON::XS is surprisingly fast, as shown in the following
tables. They have been generated with the help of the C<eg/bench> program
in the JSON::XS distribution, to make it easy to compare on your own
system.

First comes a comparison between various modules using
a very short single-line JSON string (also available at
L<http://dist.schmorp.de/misc/json/short.json>).

   {"method": "handleMessage", "params": ["user1",
   "we were just talking"], "id": null, "array":[1,11,234,-5,1e5,1e7,
   true,  false]}

It shows the number of encodes/decodes per second (JSON::XS uses
the functional interface, while JSON::XS/2 uses the OO interface
with pretty-printing and hashkey sorting enabled, JSON::XS/3 enables
shrink). Higher is better:

   module     |     encode |     decode |
   -----------|------------|------------|
   JSON 1.x   |   4990.842 |   4088.813 |
   JSON::DWIW |  51653.990 |  71575.154 |
   JSON::PC   |  65948.176 |  74631.744 |
   JSON::PP   |   8931.652 |   3817.168 |
   JSON::Syck |  24877.248 |  27776.848 |
   JSON::XS   | 388361.481 | 227951.304 |
   JSON::XS/2 | 227951.304 | 218453.333 |
   JSON::XS/3 | 338250.323 | 218453.333 |
   Storable   |  16500.016 | 135300.129 |
   -----------+------------+------------+

That is, JSON::XS is about five times faster than JSON::DWIW on encoding,
about three times faster on decoding, and over forty times faster
than JSON, even with pretty-printing and key sorting. It also compares
favourably to Storable for small amounts of data.

Using a longer test string (roughly 18KB, generated from Yahoo! Locals
search API (L<http://dist.schmorp.de/misc/json/long.json>).

   module     |     encode |     decode |
   -----------|------------|------------|
   JSON 1.x   |     55.260 |     34.971 |
   JSON::DWIW |    825.228 |   1082.513 |
   JSON::PC   |   3571.444 |   2394.829 |
   JSON::PP   |    210.987 |     32.574 |
   JSON::Syck |    552.551 |    787.544 |
   JSON::XS   |   5780.463 |   4854.519 |
   JSON::XS/2 |   3869.998 |   4798.975 |
   JSON::XS/3 |   5862.880 |   4798.975 |
   Storable   |   4445.002 |   5235.027 |
   -----------+------------+------------+

Again, JSON::XS leads by far (except for Storable which non-surprisingly
decodes faster).

On large strings containing lots of high Unicode characters, some modules
(such as JSON::PC) seem to decode faster than JSON::XS, but the result
will be broken due to missing (or wrong) Unicode handling. Others refuse
to decode or encode properly, so it was impossible to prepare a fair
comparison table for that case.


=head1 SECURITY CONSIDERATIONS

When you are using JSON in a protocol, talking to untrusted potentially
hostile creatures requires relatively few measures.

First of all, your JSON decoder should be secure, that is, should not have
any buffer overflows. Obviously, this module should ensure that and I am
trying hard on making that true, but you never know.

Second, you need to avoid resource-starving attacks. That means you should
limit the size of JSON texts you accept, or make sure then when your
resources run out, that's just fine (e.g. by using a separate process that
can crash safely). The size of a JSON text in octets or characters is
usually a good indication of the size of the resources required to decode
it into a Perl structure. While JSON::XS can check the size of the JSON
text, it might be too late when you already have it in memory, so you
might want to check the size before you accept the string.

Third, JSON::XS recurses using the C stack when decoding objects and
arrays. The C stack is a limited resource: for instance, on my amd64
machine with 8MB of stack size I can decode around 180k nested arrays but
only 14k nested JSON objects (due to perl itself recursing deeply on croak
to free the temporary). If that is exceeded, the program crashes. To be
conservative, the default nesting limit is set to 512. If your process
has a smaller stack, you should adjust this setting accordingly with the
C<max_depth> method.

Something else could bomb you, too, that I forgot to think of. In that
case, you get to keep the pieces. I am always open for hints, though...

Also keep in mind that JSON::XS might leak contents of your Perl data
structures in its error messages, so when you serialise sensitive
information you might want to make sure that exceptions thrown by JSON::XS
will not end up in front of untrusted eyes.

If you are using JSON::XS to return packets to consumption
by JavaScript scripts in a browser you should have a look at
L<http://jpsykes.com/47/practical-csrf-and-json-security> to see whether
you are vulnerable to some common attack vectors (which really are browser
design bugs, but it is still you who will have to deal with it, as major
browser developers care only for features, not about getting security
right).


=head1 THREADS

This module is I<not> guaranteed to be thread safe and there are no
plans to change this until Perl gets thread support (as opposed to the
horribly slow so-called "threads" which are simply slow and bloated
process simulations - use fork, it's I<much> faster, cheaper, better).

(It might actually work, but you have been warned).


=head1 BUGS

While the goal of this module is to be correct, that unfortunately does
not mean it's bug-free, only that I think its design is bug-free. If you
keep reporting bugs they will be fixed swiftly, though.

Please refrain from using rt.cpan.org or any other bug reporting
service. I put the contact address into my modules for a reason.

=cut

our $true  = do { bless \(my $dummy = 1), "JSON::XS::Boolean" };
our $false = do { bless \(my $dummy = 0), "JSON::XS::Boolean" };

sub true()  { $true  }
sub false() { $false }

sub is_bool($) {
   UNIVERSAL::isa $_[0], "JSON::XS::Boolean"
#      or UNIVERSAL::isa $_[0], "JSON::Literal"
}

XSLoader::load "JSON::XS", $VERSION;

package JSON::XS::Boolean;

use overload
   "0+"     => sub { ${$_[0]} },
   "++"     => sub { $_[0] = ${$_[0]} + 1 },
   "--"     => sub { $_[0] = ${$_[0]} - 1 },
   fallback => 1;

1;

=head1 SEE ALSO

The F<json_xs> command line utility for quick experiments.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

