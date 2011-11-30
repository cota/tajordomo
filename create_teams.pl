#!/usr/bin/perl
# create_teams.pl
# Processes an mbox file with messages from students in which they list
# the names and UNI's of their team members.
# This script assigns a unique team ID to each of these emails,
# and then creates teamX.mail files to notify the team members of
# their team ID.

use warnings;
use strict;

use Mail::Box::Manager;
use Getopt::Long;
use Tajordomo;

sub usage {
	print STDERR <<EOT;
create_teams.pl [options] file.mbox
  Creates unique team ID's from the UNI's specified in file.mbox.
  Prints the list of teams and members to stdout.
  Options:
    --students	<str> * File with the list of registered students.
		        Default: students.txt
    -: Takes the mbox file from stdin.
EOT
	exit(1);
}

my $stdio = 0;
my $students_file = 'students.txt';

my $rc = GetOptions(
    'students=s' => \$students_file,
    '' => \$stdio,
    );

my $mbox;
if ($stdio) {
    $mbox = "-";
} elsif (@ARGV) {
    $mbox = $ARGV[0];
} else {
    print STDERR "Missing input mbox\n";
    usage();
}

my $students = read_students_list($students_file);

my $mgr    = Mail::Box::Manager->new;
my $folder = $mgr->open($mbox);

my $team_id = 0;
my %teams;

foreach my $message ($folder->messages) {
    my @UNIs = ($message->body =~ m/([a-z]{2,3}[0-9]{4})/g);
    my $added = 0;
    my $members = 0;

    ++$team_id;

    foreach (@UNIs) {
	if ($students->{$_}) {
	    $members++;
	    if (!$students->{$_}->{team}) {
		$students->{$_}->{team} = $team_id;
		push @{ $teams{$team_id} }, $_;
		$added++;
	    }
	}
    }

    if ($added) {
	if ($members < $added) {
	    print STDERR "Warning: $team_id has $added members instead of ",
	    "$members, as requested";
	}
    } else {
	$team_id--;
    }
}
$folder->close;

foreach my $team (sort { $a <=> $b } keys %teams) {
    my $mailfile = "team$team.mail";

    open(my $fh, ">$mailfile") or die ("Cannot open $mailfile");

    print "team$team: ", join(", ", @{$teams{$team}}), "\n";

    print $fh "To: ", join(", ", map {
	sprintf "$students->{$_}->{name} $students->{$_}->{surname} <$_\@columbia.edu>"
			   } @{$teams{$team}}), "\n";
    print $fh "Subject: [$course_shortname] Project Team Info: team $team\n";
    print $fh "\n";
    print $fh "Hi ",
    join(" + ", map { sprintf "$students->{$_}->{name}" } @{$teams{$team}}), ",\n";

# now comes the gist of the email. I'm too lazy to abstract this--just
# adapt it to your needs.
    print $fh <<EOT;

You have been assigned team number $team for the project.  When
preparing the tarball to submit your report, remember to pass your
team number to the build script, ie:

        \$ make TEAM=$team

Do not forget that the project is due on Monday, December 19th at
11:59pm EST. Plan your work well in advance--make sure you have
a reasonable amount of time to run simulations and write a high
quality report.

If you have questions, you can post them on the forum. You can also
come to my office hours, which are held in the TA room on Thursdays
between 4 and 6pm. Make use of these two resources!

Good luck,

		Emilio
EOT

    close($fh) or die("Cannot close $mailfile");
}
