use JSON::Fast;

enum Type <init object array string number key end-key wait-sep value end-value item>;

class State {
    has         @.subscribed;
    has Type    @.types;
    has Str     @.path = '$';
    has Str     %.cache is default("");

    method type { @!types.tail }
    method path-key(@path = @!path) { @path.join: "." }
    method add-to-cache($chunk, :%cache = %!cache, :@path = @!path --> Hash()) {
        |%cache,
        |do for @path.produce: &[,] -> @p {
            my $path = self.path-key: @p;
            do if @p ~~ @!subscribed.any {
                $path => %cache{$path} ~ $chunk
            }
        }
    }
    method remove-from-cache($chunk, :%cache = %!cache, :@path = @!path --> Hash()) {
        |self.add-to-cache($chunk, :%cache, :path(self.pop-path: :@path)).grep: { .key !~~ self.path-key: @path }
    }
    method add-type(Type $type, Type :@types = @!types      --> List) { |@types, $type }
    method change-type(Type $type, Type :@types = @!types   --> List) { |@types.head(*-1), $type }
    method pop-type(Type @types = @!types                   --> List) { |@types.head: *-1 }
    method pop-path(Str :@path = @!path                     --> List) { |@path.head: *-1 }
    method add-path(Str $path, :@path = @!path              --> List) { |@path, $path }
    method increment-path(Str :@path = @!path               --> List) {
		#say @path;
        my Str $new-index = ~(@path.tail + 1);
        self.add-path: :path(self.pop-path: :@path), $new-index
    }
    method cond-emit(:%cache = %!cache, :@path = @!path)            {
		#say "cond-emit {%cache.perl}, {@path.perl}";
        my $path = self.path-key: @path;
        emit %cache{$path}:p if @path ~~ @!subscribed.any
    }
    method cond-emit-concat($chunk = "", :%cache = %!cache, :@path = @!path) {
		#say "cond-emit-concat {$chunk.perl}, {%cache.perl}, {@path.perl}";
        self.cond-emit: :cache(self.add-to-cache: $chunk), :@path
    }
}

constant @stop-words = '{', '}', '[', ']', '"', ':', ',';

proto parse(State:D $state, Str $chunk --> State:D) {
	#say "parse {$state.perl}, {$chunk.perl}";
    {*}
}
multi parse($_, '{') {
    .clone: :types(.add-type: object), :cache(.add-to-cache: '{')
}
multi parse($_, '[') {
    .clone: :types(.add-type: array), :cache(.add-to-cache: '['), :path(.add-path: "0")
}
multi parse($_ where .type ~~ object, '"') {
    .clone: :types(.add-type: key), :cache(.add-to-cache: '"')
}
multi parse($_ where .type ~~ key, $key) {
    .clone: :types(.change-type: end-key), :cache(.add-to-cache: $key), :path[.add-path: $key]
}
multi parse($_ where .type ~~ end-key, '"') {
    .clone: :types(.change-type: value), :cache(.add-to-cache: '"', :path(.pop-path))
}
multi parse($_ where .type ~~ value, ':') {
    .clone: :types(.change-type: value), :cache(.add-to-cache: ':', :path(.pop-path))
}
multi parse($_ where .type ~~ string.none, '"') {
    .clone: :types(.add-type: string), :cache(.add-to-cache: '"')
}
multi parse($_ where .type ~~ string, $chunk) {
    .clone: :cache(.add-to-cache: $chunk)
}
multi parse($_ where .type ~~ string, '"') {
    .cond-emit-concat: '"';
    .clone: :types(.pop-type), :cache(.remove-from-cache: '"')
}
multi parse($_ where .type ~~ value, ',') {
    .clone: :types(.pop-type), :cache(.add-to-cache: ','), :path(.pop-path)
}
multi parse($_ where .type ~~ array, ',') {
    .clone: :cache(.add-to-cache: ','), :path(.increment-path)
}
multi parse($_ where .type ~~ array, ']') {
    .cond-emit-concat: ']', :path(.pop-path);
    .clone: :types(.pop-type), :cache(.remove-from-cache: ']'), :path(.pop-path)
}
multi parse($_ where .type ~~ value, '}') {
    .cond-emit-concat: '}', :path(.pop-path);
    .clone: :types(.pop-type), :cache(.remove-from-cache: '}'), :path(.pop-path)
}
multi parse($_ where .type ~~ object, '}') {
    .cond-emit-concat: '}', :path(.pop-path);
    .clone: :types(.pop-type), :cache(.remove-from-cache: '}'), :path(.pop-path)
}
multi parse($_ where .type ~~ string, $chunk) {
    .clone: :cache(.add-to-cache: $chunk)
}
multi parse($_, $chunk) {
    .cond-emit-concat: $chunk;
    .clone: :cache(.add-to-cache: $chunk)
}

sub json-stream(Supply $supply, @subscribed) is export {
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
            .emit for @new-chunks;
			LAST .emit for @rest;
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
			#say $value;
            emit $key => from-json $value
        }
    }
}
