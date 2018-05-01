use JSON::Stream::State;
use JSON::Stream::Type;
unit class Parser;

has         @.subscribed;
has Type    @.types = init;
has Str     @.path = '$';
has Str     %.cache is default("");

method json-path($num = 0) { @!path.head(* - $num).join: "." }

#my $*DEBUG = True;
sub debug(|c) { note |c if $*DEBUG }
constant @stop-words = '{', '}', '[', ']', '"', ':', ',';

method add-to-cache($chunk, $from = 0) {
    for $from .. (@!path - 1) -> $i {
        my @p = |@!path.head(* - $i);
        %!cache{self.json-path: $i} ~= $chunk if @p ~~ @!subscribed.any
    }
}

method emit-pair($num = 0) {
    my @p = |@!path.head(* - $num);
    emit self.json-path($num) => %!cache{self.json-path: $num}:delete if @p ~~ @!subscribed.any
}

multi method parse(Str $chunk) {
    debug "self.parse: {@!types.tail}, $chunk";
    #dd %!cache;
    self.parse: @!types.tail, $chunk
}

multi method parse($ where none(string, key), $chunk where * ~~ @stop-words.none) {
    debug "parse generic";
    self.add-to-cache: $chunk;
    self.emit-pair;
    #.cond-emit-concat: $chunk;
    # .clone: :cache(.remove-from-cache: $chunk)
}

# STRING
# string start
multi method parse($ where none(string, object, key), '"') {
    debug "parse string start";
    @!types.push: string;
    self.add-to-cache: '"';
    #.clone: :types(.add-type: string), :cache(.add-to-cache: '"')
}

# string body
multi method parse(string, $chunk) {
    debug "parse string body";
    self.add-to-cache: $chunk;
    #.clone: :cache(.add-to-cache: $chunk)
}

# string end
multi method parse(string, '"') {
    debug "parse string end";
    self.add-to-cache: '"';
    self.emit-pair;
    @!types.pop;
    #.cond-emit-concat: '"';
    #.clone: :types(.pop-type), :cache(.remove-from-cache: '"')
}

# OBJECT
# object start
multi method parse($_, '{') {
    debug "parse object start";
    self.add-to-cache: '{';
    @!types.push: object;
    #.clone: :types(.add-type: object), :cache(.add-to-cache: '{')
}

# object key start
multi method parse(object, '"') {
    debug "parse object key start";
    self.add-to-cache: '"';
    @!types.push: key;
    #.clone: :types(.add-type: key), :cache(.add-to-cache: '"')
}

# object key body
multi method parse(key, $key where * ~~ @stop-words.none) {
    debug "parse object key body";
    self.add-to-cache: $key;
    @!path.push: $key;
    #.clone: :cache(.add-to-cache: $key), :path[.add-path: $key]
}

# object key end
multi method parse(key, '"') {
    debug "parse object key end";
    self.add-to-cache: '"', 1;
    @!types.pop;
    #.clone: :type(.pop-type), :cache(.add-to-cache: '"', :path(.pop-path))
}

# object key sep
multi method parse(object, ':') {
    debug "parse object key sep";
    self.add-to-cache: ':', 1;
    @!types.push: value;
    #.clone: :types(.change-type: value), :cache(.add-to-cache: ':', :path(.pop-path))
}

# object sep
multi method parse(value, ',') {
    debug "parse object sep";
    self.add-to-cache: ',';
    @!types.pop;
    @!path.pop;
    #.clone: :types(.pop-type), :cache(.add-to-cache: ','), :path(.pop-path)
}

# object end
multi method parse($ where any(value, object), '}') {
    debug "parse object end";
    @!path.pop;
    self.add-to-cache: '}';
    self.emit-pair;
    @!types.pop;
    @!types.pop if @!types.tail ~~ object;
    #.cond-emit-concat: '}', :path(.pop-path);
    #.clone: :types(.pop-type: .type ~~ object ?? 1 !! 2), :cache(.remove-from-cache: '}', :path(.pop-path)), :path(.pop-path)
}

# ARRAY
# array start
multi method parse($, '[') {
    debug "parse array start";
    self.add-to-cache: '[';
    @!types.push: array;
    @!path.push: "0";
    #.clone: :types(.add-type: array), :cache(.add-to-cache: '['), :path(.add-path: "0")
}

# array sep
multi method parse(array, ',') {
    debug "parse array sep";
    self.add-to-cache: ',';
    %!cache{@.json-path}:delete;
    @!path.tail++;
    #.clone: :cache(.remove-from-cache: ','), :path(.increment-path)
}

# array end
multi method parse(array, ']') {
    debug "parse array end";
    self.add-to-cache: ']', 1;
    self.emit-pair: 1;
    @!types.pop;
    @!path.pop;
    #.cond-emit-concat: ']', :path(.pop-path);
    #.clone: :types(.pop-type), :cache(.remove-from-cache: ']'), :path(.pop-path)
}

