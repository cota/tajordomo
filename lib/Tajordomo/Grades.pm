package Tajordomo::Grades;

=for args
Usage:  tajordomo grades <command> [options] <files>

Commands:
    stats			Extract statistics from the grades.
    csv				Export grades in CSV format.
Mandatory options:
    --rubric			Path to the rubric file.
Options:
    stats --n_bins		Number of bins for the histogram. The default
                                is given by Scott's normal reference rule.
    --help -h			Display this help message.
Non-option arguments:
    files			Grade file(s).

=cut

@EXPORT = qw(
  process_grades
  grades
);

use Exporter 'import';
use Getopt::Long;
use YAML::XS qw(LoadFile);
use Text::CSV;
use Statistics::Descriptive;

use Tajordomo::Common;
use Tajordomo::Rc;
use Tajordomo::HOP;
use Tajordomo::Users;
use Tajordomo::Teams::Common;

use strict;
use warnings;

my $rubric_path;
my $rubric;
my %csv_grades;
my $csv_tid;

sub load_rubric {
    my ($rpath) = @_;

    if (!defined($rpath)) {
	say2 "No path to rubric given.";
	exit 1;
    }
    $rubric = LoadFile($rpath);
}

sub grades {
    my ($stats, $csv, $n_bins) = args();

    my @grade_files;
    if (@ARGV) {
	@grade_files = @ARGV;
    } else {
	say2 "Missing input grade files";
	exit 1;
    }

    my @grades = ();
    foreach (@grade_files) {
	push @grades, LoadFile($_);
    }
    process_grades($rubric_path, \@grades);

    if ($stats) {

	my @totals = ();
	foreach my $g (@grades) {
	    push @totals, $g->{_TOTAL};
	}
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(@totals);

	my $mean = $stat->mean();
	my $pretty_mean = sprintf("%.2f", $mean);

	my $std  = $stat->standard_deviation();
	my $pretty_std = sprintf("%.2f", $std);

	my $median = $stat->median();
	my $pretty_median = sprintf("%.2f", $median);

	say "mean: $pretty_mean";
	say "stddev: $pretty_std";
	say "median: $pretty_median";
	if ($stat->count() > 1) {
	    say "histogram:";
	    print histogram_text($n_bins, $stat);
	}
    } elsif ($csv) {
	my $csv = Text::CSV->new ( { binary => 1, eol => $/ } )
	    or die "Cannot use CSV: ".Text::CSV->error_diag ();

	my @rows = ();

	my %users = get_users();
	my @users_inorder = sort keys %users;

	my @fields = ('surname', 'name', 'id', 'team');

	my @titles = ();
	my ($k,$v) = each %csv_grades;
	foreach (sort keys %$v) {
	    push @titles, $_ if $_ ne 'id';
	}
	push @rows, [ @fields, @titles ];

	foreach my $s (@users_inorder) {
	    my @row = ();
	    my $tid = team_of_user($s);
	    push @row, $users{$s}->{surname}, $users{$s}->{name}, $s;
	    if ($tid) {
		push @row, $tid;
		foreach (@titles) {
		    push @row, $csv_grades{$tid}->{$_};
		}
	    }
	    push @rows, \@row;
	}

	$csv->print (*STDOUT, $_) for @rows;
    }
}

sub process_grades {
    my ($rpath, $rawgrades) = @_;

    load_rubric($rpath);

    foreach my $g (@$rawgrades) {
	$csv_tid = $g->{team};
	if (hash_walk($g, [], \&csv_store)) {
	    die("Fatal: invalid input for team $g->{team}.\n");
	}
    }

    inspect_grades($rawgrades);

    foreach my $g (@$rawgrades) {
	$g->{_TOTAL} = hash_walk($g, [], \&calc_score);
	$csv_grades{$g->{team}}->{_total} = $g->{_TOTAL};
    }
}

sub csv_store {
    my ($href, $k, $v, $key_list) = @_;

    if (!exists($href->{score}) && $k eq 'comm') {
	my $str = '';
	my $val = calc_deductions($v, $key_list, \$str);
	my $title = join(' ', @$key_list);
	$csv_grades{$csv_tid}->{$title} = $str;
	$href->{'_COMM'} = $str;
	my @valtitle = @$key_list;
	pop @valtitle;
	push @valtitle, 'score';
	$title = join(' ', @valtitle);
	$csv_grades{$csv_tid}->{$title} = $val;
	$href->{'_SCORE'} = $val;
	return 0;
    }

    if ($k eq 'score' || $k eq 'comm') {
	my $title = join(' ', @$key_list);
	$csv_grades{$csv_tid}->{$title} = $v;

	my $f = '_' . uc $k;
	$href->{$f} = $v;
    }
    return 0;
}

sub histogram_text {
    my ($n_bins, $stat) = @_;

    if ($n_bins == 0) {
	my $w = 3.49 * $stat->standard_deviation() / $stat->count()**(1/3);
	$n_bins = ($stat->max() - $stat->min()) / $w;
	$n_bins = int($n_bins + 0.999);
    }
    my %dist = $stat->frequency_distribution($n_bins);
    my $width = ($stat->max() - $stat->min()) / $n_bins;

    my $str = '';
    foreach (sort {$a <=> $b} keys %dist) {
	$str .= sprintf("%6d-%-6d", $_ - $width, $_);
	$str .= " " . "#" x $dist{$_} . "\n";
    }
    return $str;
}

sub calc_score
{
    my ($href, $k, $v, $key_list) = @_;

    return $k eq '_SCORE' ? $v : 0;
}

sub calc_deductions
{
    my ($x, $key_list, $ref) = @_;
    my @list = @$key_list;
    pop @list;
    push @list, 'max';
    my $max = hash_leaf($rubric, \@list);
    pop @list;

    load_rubric($rubric_path) if !%$rubric;

    my $retval = $max;
    return $retval if !$x;

    push @list, 'deductions';
    while ($x =~ /\$\(([_a-zA-Z0-9]+)\)/g) {
	my $id = $1;
	push @list, $id;
	my $href = hash_leaf($rubric, \@list);
	if ($href) {
	    my $t = $href->{t};
	    my $v = $href->{v};

	    if ($v > 0) {
		$retval = $v;
	    } else {
		$retval += $v;
	    }
	    if ($ref) {
		$x =~ s/\$\($id\)/$t ($v)/;
	    }
	} else {
	    say2 "Warning: ($id) doesn't exist in ",
	    join("->", @list[0..$#list-1]), ".";
	}
	pop @list;
    }
    $$ref .= $x;
    return $retval;
}

sub inspect_grades
{
    my ($grades) = @_;

    foreach my $g (@$grades) {
	if (hash_walk($g, [], \&check_score)) {
	    die("Fatal: invalid input for team $g->{team}.\n");
	}
    }
}

sub check_score
{
    my ($hash, $k, $v, $key_list) = @_;

    if ($k eq '_SCORE') {
	my $last = pop @$key_list;
	my $max = hash_leaf($rubric, $key_list);
	push @$key_list, $last;
	if ($v < 0 || $v > $max) {
	    say2 "Warning: $v out of range [0, $max] for '@$key_list'.";
	    return -1;
	}
    }
    return 0;
}

sub args {
    my $stats = 0;
    my $csv = 0;

    my $n_bins = 0;
    GetOptions(
	'n_bins=i'	=> \$n_bins,
        'rubric=s'	=> \$rubric_path,
    ) or usage();

    my ($cmd) = shift @ARGV;
    usage() if not $cmd;

    if ($cmd eq 'stats') {
	$stats = 1;
    } elsif ($cmd eq 'csv') {
	$csv = 1;
    } else {
	say2 "grades: Unknown subcommand `$cmd'.";
	usage();
    }
    return ($stats, $csv, $n_bins);
}

1;
