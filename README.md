[![Build Status](https://travis-ci.org/FCO/JSON-Stream.svg?branch=master)](https://travis-ci.org/FCO/JSON-Stream)

JSON::Stream
============

A JSON stream parser

```raku
use JSON::Stream;
```

```raku
plan 6;
react whenever json-stream "a-big-json-file.json".IO.open.Supply, '$.employees.*' -> (:$key, :$value) {
    [
        {
            is $key,         '$.employees.0';
            is $value<name>, 'John';
            is $value<age>,  40;
        },
        {
            is $key,         '$.employees.1';
            is $value<name>, 'Peter';
            is $value<age>,  30;
        }
    ].[$++].()
}
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
plan 4;
react whenever json-stream Supply.from-list(< { "bla" : [1,2,3,4], >), '$.bla.*' -> (:key($), :$value) {
   is $value, ++$
}
```

### sub json-stream

```raku
sub json-stream(
    Supply $supply,
    +@subscribed
) returns Supply
```

Receives an supply and a list of simplified json-path strings

