package Tajordomo::Teams::Common;

@EXPORT = qw(
  team_add
  team_commit
  team_members
  team_of_user
  teams_file_exists
  teams_init
);

use Exporter 'import';
use Getopt::Long;
use List::Util qw(max);

use Tajordomo::Common;
use Tajordomo::Rc;
use Tajordomo::Input::Common;
use Tajordomo::Users;

use strict;
use warnings;

my %teams;
my $max_tid = 0;
my %users;
my $teamfile = ".tajordomo/teams";

sub teams_file_exists {
    return -f $teamfile;
}

sub read_teams_from_file {
    return if !teams_file_exists();
    return if %teams;

    open(my $fh, "<", $teamfile) or die("cannot open $teamfile: $!");
    while (<$fh>) {
	chomp;

	my @fields = split(": ");

	my $team = $fields[0];
	$team =~ m/^(\d+)/;
	my $id = $1;
	$max_tid = max($max_tid, $id);
	my $members = $fields[1];
	my @members = split(", ", $members);
	foreach (@members) {
	    $users{$_} = $id;
	}
	if ($teams{$id}) {
	    say2 "Warning: duplicated team '$id'";
	}
	$teams{$id} = \@members;
    }
    close($fh) or die("Cannot close $teamfile: $!");
}

sub team_add {
    my @members = @_;

    foreach (@members) {
	my $tou = team_of_user($_);
	if ($tou) {
	    say2 "Error: user '$_' already in team $tou";
	    exit 1;
	}
    }
    push @{ $teams{++$max_tid} }, @members;
    foreach (@members) {
	$users{$_} = $max_tid;
    }
}

sub team_commit {
    open(my $fh, ">", $teamfile) or die "Cannot open $teamfile: $!";
    foreach my $k (sort { $a <=> $b } keys %teams) {
	print $fh "$k: ", join(", ", @{ $teams{$k} }), "\n";
    }
    close($fh) or die("Cannot close $teamfile");

    undef %teams;
    $max_tid = 0;
    read_teams_from_file();
}

sub team_of_user {
    my $user_id = shift;

    return $users{$user_id} || undef;
}

sub team_members {
    my $team_id = shift;

    return @{ $teams{$team_id} } || undef;
}

sub teams_init {
    read_teams_from_file();
}

1;
