use v6;
use lib 'lib';

use Test;
use Test::META;

use Pod::Test::Code;

plan 2;

# That's it
meta-ok();

subtest {
    test-code-snippets;
}

done-testing;
