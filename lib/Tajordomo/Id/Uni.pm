package Tajordomo::Id::Uni;

@EXPORT = qw(
  _match_ids
);

use Exporter 'import';

use strict;
use warnings;

sub _match_ids {
    my $msg = shift;

    my @ids = map { lc $_ } ($msg =~ m/\W?([a-z]{2,3}[0-9]{2,4})\W?/ig);
    return @ids;
}
