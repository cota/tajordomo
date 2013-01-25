package Tajordomo::Users;

@EXPORT = qw(
  get_users
  users
  users_file_exists
  users_dont_exist
);

use Exporter 'import';
use Getopt::Long;

use Tajordomo::Common;
use Tajordomo::Rc;
use Tajordomo::Input::Common;
use Tajordomo::Users;

use strict;
use warnings;

my %users;

sub users_file_exists {
    return -f ".tajordomo/users";
}

# Format of the input file:
# ID\tName\tSurname\tfoo@bar
sub read_users {
    if (!users_file_exists()) {
	say2 "No users' list file.";
	exit 1;
    }
    return if %users;

    my $filename = ".tajordomo/users";
    open(my $fh, "<", $filename) or die("cannot open $filename");
    while (<$fh>) {
	chomp;

	my @fields = split("\t");
	if (@fields == 4) {
	    my $id	= $fields[0];
	    my $name	= $fields[1];
	    my $surname	= $fields[2];
	    my $email	= $fields[3];

	    if ($users{$id}) {
		say2 "Warning: duplicated user '$id'";
	    }
	    $users{$id}->{name}		= $name;
	    $users{$id}->{surname}	= $surname;
	    $users{$id}->{email}	= $email;
	}
    }
    close($fh) or die("Cannot close $filename");
}

sub get_users {
    read_users();
    return %users;
}

sub users_dont_exist {
    my @users = @_;
    my @mismatches = ();

    read_users();

    foreach (@users) {
	push @mismatches, $_ if !$users{$_};
    }
    return @mismatches;
}

sub users {
    my $argv = args();
    my $cmd = shift @ARGV;

    if ($cmd eq 'create') {
	if (!@ARGV) {
	    say2 "create: Argument required.";
	    exit 1;
	}
	my $args = join(" ", @ARGV);
	create($args);
    } else {
	say2 "teams: Invalid subcommand '$cmd'.";
	exit 1;
    }
}

sub args {
    my $help = 0;
    my $argv = join(" ", @ARGV);

    GetOptions(
        'help|h'        => \$help,
    ) or usage();
    usage() if $help;

    if (!@ARGV) {
	say2 "users: Argument required.";
	exit 1;
    }

    return $argv;
}

1;
