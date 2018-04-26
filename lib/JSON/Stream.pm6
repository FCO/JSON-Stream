use JSON::Fast;

enum Type <init object array string number key end-key wait-sep value item>;

class State {
    has         @.subscribed;
    has Type    @.types;
    has Str     @.path = '$';
    has Str     %.cache is default("");
}

constant @stop-words = '{', '}', '[', ']', '"', ':', ',';

sub path-key(+@path) { @path.join: "." }

proto parse(State:D, Str --> State:D) { * }
multi parse($_, '{') {
    my $path  = path-key .path;
    my @p = .path;
    my @s = .subscribed;
    if @p ~~ @s {
        return .clone: :types(|.types, object), :cache(($path => .cache{$path} ~ '{').Hash)
    }
    .clone: :types(|.types, object)
}
multi parse($_ where .types.tail ~~ object, '"') {
    my $path  = path-key .path;
    with .cache{$path} -> $cache {
        return .clone: :types[|.types, key], :cache(|.cache, $path => .cache{$path} ~ '"')
    }
    .clone
}
multi parse($_ where .types.tail ~~ key, $key) {
    # TODO: change path
    my $path  = path-key .path;
    with .cache{$path} -> $cache {
        return .clone: :types[|.types.head(*-1), end-key], :cache(|.cache, $path => .cache{$path} ~ $key)#, :path[|.path, $key]
    }
    .clone: :path[|.path, $key]
}
multi parse($_ where .types.tail ~~ end-key, '"') {
    my $path  = path-key .path;
    with .cache{$path} -> $cache {
        return .clone: :types[|.types.head(*-1), wait-sep], :cache(|.cache, $path => .cache{$path} ~ '"')
    }
    .clone
}
multi parse($_ where .types.tail ~~ wait-sep, '}') {
    parse .clone(:types(.types.head(*-1))), '}'
}
multi parse($_ where .types.tail ~~ object, '}') {
    my $path  = path-key .path;
    with .cache{$path} -> $cache {
        emit $path => $cache ~ '}' if .types.elems == 1;
        .clone: :cache(.cache.grep(*.key !~~ $path).Hash), :types(.types.head: *-1), :path(.path.head: *-1)
    }
    .clone: :path(.path.head: *-1)
}
multi parse($state, $chunk) {
    #note "parse {$state.perl}, {$chunk.perl}";
    my $path  = path-key $state.path;
    with $state.cache{$path} -> $cpath {
        return $state.clone: :cache((|$state.cache, $path => $cpath ~ $chunk).Hash)
    }
    $state
}

sub json-stream(Supply $supply, *@subscribed) is export {
    my $s1 = supply {
        my @rest;
        whenever $supply -> $chunk {
            my @chunks = $chunk.comb: /'[' || ']' || '{' || '}' || '"' || ':' || ',' || <-[[\]{}":,]>+/;
            @chunks .= grep: * !~~ /^\s+$/;
            if @rest {
                @rest.tail ~= @chunks.shift;
            }
            my @new-chunks = |@rest, |@chunks;
            @rest = ();
            @rest.unshift: @new-chunks.pop while @new-chunks and @new-chunks.tail !~~ @stop-words.one;
            .emit for @new-chunks
        }
    }
    my $s2 = supply {
        my State $state .= new: :@subscribed;
        whenever $s1 -> $chunk {
            $state = parse $state, $chunk;
        }
    }
    supply {
        whenever $s2 -> (:$key, :$value) {
            emit $key => from-json $value
        }
    }
}
