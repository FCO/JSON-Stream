use JSON::Fast;

enum Type <init object array string number key value item>;

class State {
    has         @.subscribed;
    has Type    @.types;
    has Str     @.path = '$';
    has Str     %.cache is default("");
}

constant @stop-words = '{', '}', '[', ']', '"', ':', ',';

sub path-key(+@path) { @path.join: "." }

proto parse(State:D, Str --> State:D) { * }
multi parse($state, '{') {
    my $path  = path-key $state.path;
    my @types = |$state.types, object;
    #my $cache = $state.cache{$path} ~ '{';
    if $state.path ~~ $state.subscribed {
        my $cache = $state.cache{$path} ~ '{';
        return $state.clone: :@types, :cache({$path => $cache})
    }
    $state
}
#multi parse($_ where .types.tail ~~ object, '"') {
#    my $path  = path-key .path;
#    with .cache{$path} -> $cache {
#        emit $path => $cache ~ '"';
#        .clone: :type[|.type, key], :cache(.cache.grep(*.key !~~ $path).Hash)
#    }
#    $_
#}
#multi parse($_ where .types.tail ~~ key, $key) {
#    my $path  = path-key .path;
#    with .cache{$path} -> $cache {
#        emit $path => $cache ~ $key;
#        .clone: :type[|.type, object], :cache(.cache.grep(*.key !~~ $path).Hash)
#    }
#    $_
#}
multi parse($state where .types.tail ~~ object, '}') {
    my $path  = path-key $state.path;
    with $state.cache{$path} -> $cache {
        emit $path => $cache ~ '}';
        $state.clone: :cache($state.cache.grep(*.key !~~ $path).Hash)
    }
    $state
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
