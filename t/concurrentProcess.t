#!perl -T

use Test::More tests => 1;

TODO: {
    local $TODO = "Not implemented yet";
    # Need to implement several concurrent tests to find out if
    # two concurrent runs of logparser are detected...
    ok(0);
}
