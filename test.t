use lib "lib";
use JSON::Stream;
react whenever json-stream Supply.from-list(['{', '"bla"   ', '   :', '    "bl', 'e bli blo"    , "bli":{"bla":"blu"}', '}']), [['$'], ['$', **, 'bla']] -> (:$key, :$value) {
   say "[$key => $value.perl()]"
}
#react whenever json-stream Supply.from-list(['{', '"bla"   ', '   :', '    "bl', 'e bli blo"    ', '}']), [['$',], <$ bla>] { .say }
