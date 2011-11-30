#!/usr/bin/perl
# notreg_reminder.pl
# Prepares an email to reminds students to register.

use warnings;
use strict;

use Getopt::Long;
use Tajordomo;

sub usage {
	print STDERR <<EOT;
notreg.pl [options] notreg.txt
  Prepares a reminder to the students whose UNIs are in notreg.txt.
  Options:
    --students	<str> * File with the list of registered students.
		        Default: students.txt
    -: Takes notreg.txt from stdin.
EOT
	exit(1);
}

my $stdio = 0;
my $students_file = 'students.txt';

my $rc = GetOptions(
    'students=s' => \$students_file,
    '' => \$stdio,
    );

my $notreg;
if ($stdio) {
    $notreg = "-";
} elsif (@ARGV) {
    $notreg = $ARGV[0];
} else {
    print STDERR "Missing input notreg.txt\n";
    usage();
}

my $students = read_students_list($students_file);
my @NOTREG;

open(my $fh, "<$notreg") or die ("Cannot open $notreg");
while (<$fh>) {
    chomp;
    push @NOTREG, $_;
}
close($fh) or die("Cannot close $notreg");

foreach my $uni (@NOTREG) {
    my $mailfile = "$uni.mail";

    open($fh, ">$mailfile") or die ("Cannot open $mailfile");
    print $fh "To: $students->{$uni}->{name} ";
    print $fh "$students->{$uni}->{surname} ";
    print $fh "<$uni\@columbia.edu>\n";
    print $fh "Subject: [$course_shortname] Project Registration Closed\n";
    print $fh "\n";
    print $fh "Hi $students->{$uni}->{name},\n";

# now comes the gist of the email. I'm too lazy to abstract this--just
# adapt it to your needs.
    print $fh <<EOT;

We have not yet received an email from you or your team mate (if any)
to register as a team for the final project of the course.

The deadline for registering your team has just passed--in case
you still want to do the project, send the registration email
*as described in the instructions[1]* (ie to the gmail account)
_immediately_. If you do not register, we will understand that you
are giving up on the project, in which case you will not get any
credit for it.

Thanks,

		Emilio

[1] http://www.cs.columbia.edu/~cota/cs4824/proj11/

EOT

    close($fh) or die("Cannot close $mailfile");
}
