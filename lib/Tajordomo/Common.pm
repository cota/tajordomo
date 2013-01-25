package Tajordomo::Common;

# all code in this file was taken from gitolite:
#   https://github.com/sitaramc/gitolite
# and thus everything is GPL v2.

@EXPORT = qw(
  _die
  _mkdir
  _open
  _print
  say
  say2
  slurp
  _system
  usage
);

use Exporter 'import';
use File::Path qw(mkpath);
use Carp qw(carp cluck croak confess);

use strict;
use warnings;

sub say {
    local $/ = "\n";
    print @_, "\n";
}

sub say2 {
    local $/ = "\n";
    print STDERR @_, "\n";
}

sub _die {
    if ( $ENV{D} and $ENV{D} >= 3 ) {
        confess "FATAL: " . join( ",", @_ ) . "\n" if defined( $ENV{D} );
    } elsif ( defined( $ENV{D} ) ) {
        croak "FATAL: " . join( ",", @_ ) . "\n";
    } else {
        die "FATAL: " . join( ",", @_ ) . "\n";
    }
}
$SIG{__DIE__} = \&_die;

sub usage {
    _warn(shift) if @_;
    my $script = (caller)[1];
    my $function = ( ( ( caller(1) )[3] ) || ( ( caller(0) )[3] ) );
    $function =~ s/.*:://;
    my $code = slurp($script);
    $code =~ /^=for $function\b(.*?)^=cut/sm;
    say2( $1 ? $1 : "...no usage message in $script" );
    exit 1;
}

sub _system {
    # run system(), catch errors.  Be verbose only if $ENV{D} exists.  If not,
    # exit with <rc of system()> if it applies, else just "exit 1".
    if ( system(@_) != 0 ) {
        if ( $? == -1 ) {
            die "failed to execute: $!\n" if $ENV{D};
        } elsif ( $? & 127 ) {
            die "child died with signal " . ( $? & 127 ) . "\n" if $ENV{D};
        } else {
            die "child exited with value " . ( $? >> 8 ) . "\n" if $ENV{D};
            exit( $? >> 8 );
        }
        exit 1;
    }
}

sub _mkdir {
    # it's not an error if the directory exists, but it is an error if it
    # doesn't exist and we can't create it
    my $dir  = shift;
    my $perm = shift;    # optional
    return if -d $dir;
    mkpath($dir);
    chmod $perm, $dir if $perm;
    return 1;
}

sub _open {
    open( my $fh, $_[0], $_[1] ) or _die "open $_[1] failed: $!\n";
    return $fh;
}

sub _print {
    my ( $file, @text ) = @_;
    my $fh = _open( ">", "$file.$$" );
    print $fh @text;
    close($fh) or _die "close $file failed: $! at ", (caller)[1], " line ", (caller)[2], "\n";
    my $oldmode = ( ( stat $file )[2] );
    rename "$file.$$", $file;
    chmod $oldmode, $file if $oldmode;
}

sub slurp {
    return unless defined wantarray;
    local $/ = undef unless wantarray;
    my $fh = _open( "<", $_[0] );
    return <$fh>;
}

1;
