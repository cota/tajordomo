package Tajordomo::Teams::Create;

@EXPORT = qw(
  create
);

use Exporter 'import';
use Getopt::Long;

use Tajordomo::Common;
use Tajordomo::Rc;
use Tajordomo::Input::Common;
use Tajordomo::Users;
use Tajordomo::Teams::Common;

use strict;
use warnings;

sub create {
    my ($append, $infiles) = args();

    if (!users_file_exists()) {
	say2 "Error: cannot create teams without existing users' list.";
	exit 1;
    }

    if (teams_file_exists() and !$append) {
	say2 "Error: Teams' list exists; use --append to append new users.";
	exit 1;
    }

    my @raw_teams = ();
    foreach (split " ", $infiles) {
	push @raw_teams, read_input($_);
    }
    check_unknown(\@raw_teams);

    foreach (@raw_teams) {
	team_add(@$_);
    }
    team_commit();
    say "Added ", scalar(@raw_teams), " team(s).";
}

sub check_unknown {
    my $ref = shift;
    my @flat = map { @$_ } @$ref;

    my @orphan = users_dont_exist(@flat);
    if (@orphan) {
	say2 "Error: unknown user(s): ", join(", ", @orphan), ".";
	exit 1;
    }
}

sub args {
    my $help = 0;
    my $append = 0;

    GetOptions(
	'append|a'	=> \$append,
        'help|h'        => \$help,
	) or usage();
    usage() if $help;

    my $argv = join(" ", @ARGV);

    if (!@ARGV) {
	say2 "$0: Argument required.";
	exit 1;
    }

    return ($append, $argv);
}

1;
