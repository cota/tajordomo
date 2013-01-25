package Tajordomo::List;

=for args
Usage:  tajordomo list <query>

Optional arguments:
    --help -h	Display this help message.

Non-option arguments:
    query	Matching string for listing users/teams.
                Users can be listed by team by using "team #" as the query.
                Users without team can be listed by querying "orphan".

=cut

@EXPORT = qw(
  filter
  list
);

use Exporter 'import';
use Getopt::Long;

use Tajordomo::Common;
use Tajordomo::Rc;
use Tajordomo::Users;
use Tajordomo::Teams::Common;
use Tajordomo::Users;

use strict;
use warnings;

sub filter {
    my $query = shift;

    my %u = get_users();
    my @matches = ();
    foreach my $k (keys %u) {
	$u{$k}->{id} = $k;
	$u{$k}->{tid} = team_of_user($k);

	my $r = $u{$k};
	my @entry = ($k, $r->{name}.' '.$r->{surname}, $r->{email});
	if ($r->{tid}) {
	    push @entry, "(team " . $r->{tid} . ")";
	} else {
	    push @entry, "(orphan)";
	}

	$r->{str} = join(", ", @entry);
	if (!$query or $r->{str} =~ /\Q$query\E/) {
	    push @matches, $r;
	}
    }
    return @matches;
}

sub list {
    my ($query) = args();

    my @results = filter($query);
    foreach (@results) {
	print $_->{str}, "\n";
    }
}

sub args {
    my $help = 0;

    GetOptions(
        'help|h'        => \$help,
    ) or usage();
    usage() if $help;

    my $argv = join(" ", @ARGV);

    return ($argv);
}

1;
