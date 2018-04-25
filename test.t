use lib "lib";
use JSON::Stream;
react whenever json-stream Supply.from-list(['{', '"bla"   ', '   :', '    "bl', 'e bli blo"    ', '}']), ['$'] -> (:$key, :$value) {
   say "[$key => $value.perl()]"
}
