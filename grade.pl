#!/usr/bin/perl

use warnings;
use strict;

use YAML::XS qw(LoadFile);
use Getopt::Long;
use Text::CSV;
use Text::Autoformat;
use Statistics::Descriptive;

use Tajordomo;

sub usage {
    print STDERR <<EOT;
grade.pl [options] --base=assignment.yaml grade_file1.yaml grade_file2.yaml
  Parses a grade file (in YAML) and generates a CSV to stdout + email files
  to send to the students.
  Mandatory:
  --base	<str> * Template for the assignment. Contains sections
                        to be graded, and their assigned scores.

  Options:
  --students    <str> * File with the list of students. Default: students.txt
  --teams       <str> * File with the list of teams. Default: teams.txt
EOT
exit(1);
}

my $stdio = 0;
my $students_file = 'students.txt';
my $teams_file = 'teams.txt';
my $base_file;
my $rc = GetOptions(
    'base=s' => \$base_file,
    'students=s' => \$students_file,
    'teams=s' => \$teams_file,
    '' => \$stdio,
    );

my @grade_files;
if (@ARGV) {
    @grade_files = @ARGV;
} else {
    print STDERR "Missing input grade_files\n";
    usage();
}

my $base = LoadFile($base_file);
my $template = get_base($base);

my @rawgrades = map { LoadFile($_) } @grade_files;
my %grades;

my $students = read_students_list($students_file);
my $students_inorder = read_students_inorder($students_file);
my $teams = read_teams_list($teams_file);

inspect_grades(\@rawgrades);

sub inspect_grades
{
    my ($grades) = @_;

    foreach my $g (@$grades) {
	if (hash_walk($g, [], \&check_score)) {
	    die("Fatal: invalid input for team $g->{team}.\n");
	}
    }
}

foreach my $g (@rawgrades) {
    foreach my $uni (get_unis_from_grade($g)) {
	my $s = $students->{$uni};
	my @row = ();

	push @row, $s->{surname}, $s->{name}, $uni, $g->{team};
	push @row, $g->{code}->{quality}->{score}, $g->{code}->{quality}->{comm} || '';
	push @row, $g->{code}->{performance}->{score}, $g->{code}->{performance}->{comm} || '';
	push @row, $g->{sim}->{thoroughness}->{score}, $g->{sim}->{thoroughness}->{comm} || '';
	push @row, $g->{sim}->{understanding}->{score}, $g->{sim}->{understanding}->{comm} || '';
	push @row, $g->{report}->{quality}->{score}, $g->{report}->{quality}->{comm} || '';

	$grades{$uni} = \@row;
    }
}

# XXX: The fields could be read from YAML, but they wouldn't be in order.
my @rows = ();
push @rows, ['NOTE:'];
push @rows, ['Automatically', 'Generated.', 'Do not edit!'];
my @fields = ('Last Name', 'FirstName', 'UNI', 'team', 'code quality', 'comm',
    'code performance', 'comm', 'sim thoroughness', 'comm',
	      'sim understanding', 'comm', 'report', 'comm');

push @rows, \@fields;

foreach my $uni (@$students_inorder) {
    if ($grades{$uni}) {
	push @rows, $grades{$uni};
    } else {
	my $s = $students->{$uni};
	push @rows, [ $s->{surname}, $s->{name}, $uni];
    }
}

my $csv = Text::CSV->new ( { binary => 1, eol => $/ } )
    or die "Cannot use CSV: ".Text::CSV->error_diag ();

$csv->print (*STDOUT, $_) for @rows;

# calculate average, stdev, etc
my @totals = ();
foreach my $g (@rawgrades) {
    push @totals, hash_walk($g, [], \&calc_score);
}
my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@totals);

my $mean = $stat->mean();
my $pretty_mean = sprintf("%.2f", $mean);

my $std  = $stat->standard_deviation();
my $pretty_std = sprintf("%.2f", $std);

# Prepare the email messages
foreach my $g (@rawgrades) {
    my $team = $g->{team};
    my $mailfile = "team$team.mail";

    open(my $fh, ">$mailfile") or die ("Cannot open $mailfile");

    print $fh "To: ", join(", ", map {
	sprintf "$students->{$_}->{name} $students->{$_}->{surname} <$_\@columbia.edu>"
			   } @{$teams->{$team}}), "\n";
    print $fh "Subject: [$course_shortname] Project Grade: team $team\n";
    print $fh "\n";
    print $fh "Hi ",
    join(" + ", map { sprintf "$students->{$_}->{name}" } @{$teams->{$team}}), ",\n";
    print $fh "\n";

    print $fh "We have finished grading your project. Your results are ",
    "as follows:\n\n";

    my $total = 0;
    $total += print_field($fh, $g, $template, 'code', 'quality');
    $total += print_field($fh, $g, $template, 'code', 'performance');
    $total += print_field($fh, $g, $template, 'sim', 'thoroughness');
    $total += print_field($fh, $g, $template, 'sim', 'understanding');
    $total += print_field($fh, $g, $template, 'report', 'quality');

    print $fh <<EOT;
TOTAL:\t\t\t$total / $template->{score}


FYI, the mean for all the projects is $pretty_mean / $template->{score}, and the
standard deviation is $pretty_std.

Hope you found the course and the project interesting.
Enjoy your holiday!

		Emilio
EOT
    close($fh) or die("Cannot close $mailfile");
}

sub calc_score
{
    my ($k, $v, $key_list) = @_;

    return $k eq 'score' ? $v : 0;
}

sub hash_leaf
{
    my ($hash, $list) = @_;
    my $res = $hash;

    foreach my $k (@$list) {
	$res = $res->{$k};
    }
    return $res;
}

sub check_score
{
    my ($k, $v, $key_list) = @_;

    if ($k eq 'score') {
	my $last = pop @$key_list;
	my $max = hash_leaf($template, $key_list);
	push @$key_list, $last;
	if ($v < 0 || $v > $max) {
	    print STDERR "Warning: $v out of range [0, $max] for '@$key_list'.\n";
	    return -1;
	}
    }
    return 0;
}

# from Higher Order Perl
sub hash_walk {
    my ($hash, $key_list, $callback) = @_;
    my $ret = 0;
    while (my ($k, $v) = each %$hash) {
        # Keep track of the hierarchy of keys, in case
        # our callback needs it.
        push @$key_list, $k;

        if (ref($v) eq 'HASH') {
            # Recurse.
            $ret += hash_walk($v, $key_list, $callback);
        } else {
            # Otherwise, invoke our callback, passing it
            # the current key and value, along with the
            # full parentage of that key.
            $ret += $callback->($k, $v, $key_list);
        }

        pop @$key_list;
    }
    return $ret;
}


sub print_field
{
    my ($fh, $g, $template, $cat, $subcat,) = @_;
    my $f = $g->{$cat}->{$subcat};
    my $t = $template->{$cat}->{$subcat};

    print $fh "- $cat $subcat: \t", $f->{score}, " / ", $t, "\n";
    print $fh autoformat($f->{comm}, { left => 5, right => 65 }) || "\n";

    return $f->{score};
}

sub get_unis_from_grade
{
    my $grade = shift;

    return @{$teams->{$grade->{team}}};
}

sub get_base {
    my $base = shift;
    my $score = 0;
    my $max_score = 0;
    my %b = ();

    while (my ($secname, $sec) = each(%$base)) {
	if ($secname eq 'score') {
	    $max_score = $sec;
	    $b{$secname} = $sec;
	} else {
	    foreach my $subname (keys %$sec) {
		$b{$secname}->{$subname} = $sec->{$subname};
		$score += $sec->{$subname};
	    }
	}
    }
    die("Fatal: Max score not given\n") if ($score == 0);
    die("Fatal: Score $score != Max $max_score\n") if ($score != $max_score);

    return \%b;
}
