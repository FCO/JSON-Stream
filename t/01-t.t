use JSON::Stream;
use Test;

plan 44;

react {
    whenever json-stream Supply.from-list(['42',]), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value,  42;
    }

    whenever json-stream Supply.from-list(['3.14',]), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value,  3.14;
    }

    whenever json-stream Supply.from-list(['true',]), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value,  True;
    }

    whenever json-stream Supply.from-list(['"bla"',]), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value,  "bla";
    }

    whenever json-stream Supply.from-list(['["bla"]',]), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value.^name,  "Array";
        is $value.elems, 1;
    }

    whenever json-stream Supply.from-list(['["bla", "ble", "bli"]',]), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value.^name,  "Array";
        is $value.elems, 3;
    }

    whenever json-stream Supply.from-list(['["bla", 42, 3.14, true]',]), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value.^name,  "Array";
        is $value.elems, 4;
    }

    whenever json-stream Supply.from-list(['{"bla":"ble"}',]), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value.^name,  "Hash";
        is $value.elems, 1;
    }

    whenever json-stream Supply.from-list(['{"bla":"ble", "bli": "blo"}',]), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value.^name,  "Hash";
        is $value.elems, 2;
    }

    whenever json-stream Supply.from-list(['{"bla":42, "ble":[1,2], "bli":{"blo":"blu"}}',]), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value.^name,  "Hash";
        is $value.elems, 3;
    }

    whenever json-stream Supply.from-list(<[ { "bla" : "ble" } , { "bli" : "blo" } ]>), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value.^name,  "Array";
        is $value.elems, 2;
        is $value[0].^name, "Hash";
        is $value[0].elems, 1;
        is $value[1].^name, "Hash";
        is $value[1].elems, 1;
    }

    whenever json-stream Supply.from-list(<[ { "bla" : [1,2,3] } , { "ble" : {"bli": "blo", "blu": 42} } ]>), [['$',],] -> (:$key, :$value) {
        say "$key => $value.perl()";
        is $key,    '$';
        is $value.^name,  "Array";
        is $value.elems, 2;
        is $value[0].^name, "Hash";
        is $value[0].elems, 1;
        is $value[0]<bla>.^name, "Array";
        is $value[0]<bla>.elems, 3;
        is $value[1].^name, "Hash";
        is $value[1].elems, 1;
        is $value[1]<ble>.^name, "Hash";
        is $value[1]<ble>.elems, 2;
    }
}
