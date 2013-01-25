package Tajordomo::Teams::Dispatch;

=for args
Usage:  tajordomo teams <command> [options]

Commands:
    create		Create teams from the input.
			Input can be a set of files or folders.
Options:
    --help -h		Display this help message.
=cut

@EXPORT = qw(
  teams
);

use Exporter 'import';
use Getopt::Long;

use Tajordomo::Common;

use strict;
use warnings;

sub teams {
    my ($command, @args) = @ARGV;

    usage() if not $command or $command eq '-h' or $command eq '--help';
    if ($command eq 'create') {
	shift @ARGV;
	use Tajordomo::Teams::Create;
	create();
    } else {
	say2 "teams: Invalid subcommand '$command'.";
	exit 1;
    }
}

1;
