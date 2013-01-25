# functions taken from Higher Order Perl
# http://hop.perl.plover.com/
package Tajordomo::HOP;

@EXPORT = qw(
  hash_leaf
  hash_walk
);

use Exporter 'import';

use strict;
use warnings;

sub hash_walk {
    my ($hash, $key_list, $callback) = @_;
    my $ret = 0;
    while (my ($k, $v) = each %$hash) {
        # Keep track of the hierarchy of keys, in case
        # our callback needs it.
        push @$key_list, $k;

        if (ref($v) eq 'HASH') {
            # Recurse.
            $ret += hash_walk($v, $key_list, $callback);
        } else {
            # Otherwise, invoke our callback, passing it
            # the current key and value, along with the
            # full parentage of that key.
            $ret += $callback->($hash, $k, $v, $key_list);
        }

        pop @$key_list;
    }
    return $ret;
}

sub hash_leaf
{
    my ($hash, $list) = @_;
    my $res = $hash;

    foreach my $k (@$list) {
	$res = $res->{$k};
    }
    return $res;
}

1;
