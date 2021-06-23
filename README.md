[![Build Status](https://travis-ci.org/FCO/JSON-Stream.svg?branch=master)](https://travis-ci.org/FCO/JSON-Stream)

JSON::Stream
============

A JSON stream parser

```raku
use JSON::Stream;
```

```raku
react whenever json-stream "a-big-json-file.json".IO.open.Supply, '$.employees.*' -> (:$key, :$value) {
    say "$key => $value<name> - $value<age>"
}

# OUTPUT:
# $.employees.0 => John - 40
# $.employees.1 => Peter - 30
```

Having this as an example of 'a-big-json-file.json'

```json
{
    "employees": [
        { "name": "John",  "age": 40 },
        { "name": "Peter", "age": 30 }
    ]
}
```

Warning
-------

It doesn't validate the JSON. That's good for cases where the JSON isn't properly terminated. Example:

```raku
react whenever json-stream Supply.from-list(< { "bla" : [1,2,3,4], >), '$.bla.*' -> (:key($), :$value) {
   say $value
}

# OUTPUT:
# 1
# 2
# 3
# 4
```

### sub json-stream

```raku
sub json-stream(
    Supply $supply,
    +@subscribed
) returns Supply
```

Receives an supply and a list of simplified json-path strings

