use JSON::Fast;

enum Type <object array string number key value>;
constant %stop-words = {
    '{' => { 'end' => '}',          type => object   },
    '[' => { 'end' => ']',          type => array    },
    '"' => { 'end' => '"',          type => string   },
    ':' => { 'end' => (','|'}'),    type => value    }
};

constant @stop-words = '{', '}', '[', ']', '"', ':', ',';

constant $separator = ',';
constant $pair-sep  = ':';

sub key(+@path) { @path.join: "." }

sub json-stream(Supply $supply, *@paths) is export {
    my $s1 = supply {
        my @rest;
        whenever $supply -> $chunk {
            my @chunks = $chunk.comb: /'[' || ']' || '{' || '}' || '"' || ':' || ',' || <-[[\]{}":,]>+/;
            @chunks .= grep: * !~~ /^\s+$/;
            if @rest {
                @rest[*-1] ~= @chunks.shift;
            }
            my @new-chunks = |@rest, |@chunks;
            @rest = ();
            @rest.unshift: @new-chunks.pop while @new-chunks and @new-chunks[* - 1] !~~ @stop-words.one;
            .emit for @new-chunks
        }
    }
    my $s2 = supply {
        my @type;
        my @path = '$';
        my %cache;
        my @search-for;
        whenever $supply -> $chunk {
            my $key = key(@path);
            with %stop-words{$chunk} -> \first {
                @search-for.push: first<end>;
                %cache{ $key } = $chunk if @path ~~ @paths;
                @type.push: first<type>;
            } elsif $chunk ~~ @search-for.tail {
                @search-for.shift;
                with %cache{$key} {
                    %cache{ $key } ~= $chunk;
                    emit $key => %cache{$key}:delete
                }
            }
        }
    }
    supply {
        whenever $s2 -> (:$key, :$value) {
            emit $key => from-json $value
        }
    }
}
