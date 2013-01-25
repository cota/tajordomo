package Tajordomo::Rc;

@EXPORT = qw(
  %rc
  rc_init
);

use Exporter 'import';
use Getopt::Long;
use Cwd;

use Tajordomo::Common;

use warnings;

our %rc;

$rc{TD_BINDIR} = $ENV{TD_BINDIR};
$rc{TD_LIBDIR} = $ENV{TD_LIBDIR};

my $rc = tdrc();

if (-r $rc) {
    do $rc or die $@;
    # let values specified in rc file override our internal ones
    @rc{ keys %RC } = values %RC;
}

sub tdrc {
    return getcwd . "/.tajordomo/config";
}

sub rc_init {
    my $path = shift;
    my $full_path = $path . '/.tajordomo';

    _mkdir($full_path);
    die "Existing tajordomo install at $path; aborting." if -f $full_path;

    my $conf;
    {
	local $/ = undef;
	$conf = <DATA>;
    }
    my $cfg = $full_path . "/config";
    _print($cfg, $conf) if not -f $cfg;
    say "Initialised tajordomo repository at $full_path";
}

1;

__DATA__
# Configuration variables for tajordomo

# NOTE: This is a Perl file.

%RC = (
    ID_FORMAT			=> 'uni',
    INPUT_FORMAT		=> 'mbox_dir',
#    EMAIL_FROM                  => '',
#    EMAIL_CC                    => '',
#    EMAIL_SMTP_OPTION           => '',
    );

1;
