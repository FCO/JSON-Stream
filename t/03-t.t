use JSON::Stream;
use Test;

react {
    whenever json-stream Supply.from-list(<[ { "bla" : [1,2, {"blu" : 42}] } , { "ble" : {"bli": "blo", "blu": [ 1, { "blu" : [ { "blu" : 42 } ] } ] } } ]>), < $.*.ble.**.blu > -> (:$key, :$value) {
        say "$key => $value.raku()";
        given $++ {
            when 0 {
                is $key,         '$.1.ble.blu.1.blu.0.blu';
                is $value,       42
            }
            when 1 {
                is $key,         '$.1.ble.blu.1.blu';
                isa-ok $value,   Array;
                is $value.elems, 1
            }
            when 2 {
                is $key,         '$.1.ble.blu';
                isa-ok $value,   Array;
                is $value.elems, 2
            }
        }
    }
}

done-testing
