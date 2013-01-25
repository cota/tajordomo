package Tajordomo::Init;

=for args
Usage:  tajordomo init [<options>] directory

Initialise a new tajordomo repository at the indicated location.

Optional arguments:
    --help -h		Display this help message.

Non-option arguments:
    directory		Path to the directory where the tajordomo repo is to
                        be created.

=cut

@EXPORT = qw(
  init
);

use Exporter 'import';
use Getopt::Long;

use Tajordomo::Common;
use Tajordomo::Rc;

use strict;
use warnings;

sub init {
    my ($argv) = args();

    my $dir = rc_init($argv);
}

sub args {
    my $help = 0;
    my $argv = join(" ", @ARGV);

    GetOptions(
        'help|h'        => \$help,
    ) or usage();
    usage() if $help;

    if (!@ARGV) {
	say2 "$0: Argument required.";
	exit 1;
    }

    return $argv;
}

1;
