unit module JSON::Stream:ver<0.0.4>;

=begin pod

=head1 JSON::Stream

A JSON stream parser

=begin code :lang<raku>
use JSON::Stream;
=end code

=begin code :lang<raku> :output('rx/"# OUTPUT:" \n [ ^^ <.ws> "# " ( .*? \n ) <.ws> ]*/')
react whenever json-stream "a-big-json-file.json".IO.open.Supply, '$.employees.*' -> (:$key, :$value) {
    say "$key => $value<name> - $value<age>"
}

# OUTPUT:
# $.employees.0 => John - 40
# $.employees.1 => Peter - 30
=end code

Having this as an example of 'a-big-json-file.json'

=begin code :lang<json> :file<a-big-json-file.json>
{
    "employees": [
        { "name": "John",  "age": 40 },
        { "name": "Peter", "age": 30 }
    ]
}
=end code

=head2 Warning

It doesn't validate the JSON. That's good for cases where the JSON isn't properly terminated.
Example:

=begin code :lang<raku> :output('rx/"# OUTPUT:" \n [ ^^ <.ws> "# " ( .*? \n ) <.ws> ]*/')
react whenever json-stream Supply.from-list(< { "bla" : [1,2,3,4], >), '$.bla.*' -> (:key($), :$value) {
   say $value
}

# OUTPUT:
# 1
# 2
# 3
# 4
=end code

=end pod

use JSON::Fast;
use JSON::Stream::Type;
use JSON::Stream::Parse;

constant @stop-words = '{', '}', '[', ']', '"', ':', ',';

#| Receives an supply and a list of simplified json-path strings
sub json-stream(Supply $supply, +@subscribed --> Supply) is export {
    my Parser $state .= new: :@subscribed;
    supply {
        my @rest;
        whenever $supply -> $chunk {
            my @chunks = $chunk.comb: /'[' | ']' | '{' | '}' | <!after \\> '"' | ':' | ',' | [<-[[\]{}":,]> | <after \\> '"']+/;
            @chunks .= grep: * !~~ /^\s+$/;
            if @rest and @chunks.head ~~ @stop-words.none {
                @rest.tail ~= @chunks.shift;
            }
            my @new-chunks = |@rest, |@chunks;
            @rest = ();
            @rest.unshift: @new-chunks.pop while @new-chunks and @new-chunks.tail ~~ @stop-words.none;
            $state.parse: $_ for @new-chunks;
            LAST $state.parse: $_ for @rest;
        }
    }
}
