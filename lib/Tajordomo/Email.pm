package Tajordomo::Email;

=for args
Usage:  tajordomo send-email [<options>] <query>

Options:

    --autoformat	Autoformat 'comm' fields with Text::Autoformat.
    --dry-run		Invokes git send-email with --dry-run; won't send any
                        emails.
    --confirm		Review final email body before continuing.
    --help -h		Display this help message.
    --grade=s		(Mandatory) Grade file for this email.
    --rubric=s		(Mandatory) Path to the rubric file.
    --teams -t		Send one email per team (all team members in the To:
                        field).
    --template=s	Path to the email template.
    --users -u		Send one email per user.

Non-option arguments:
    query		Query (as in `tajordomo list') to select users/teams
                        as recipients.

=cut

@EXPORT = qw(
  send_email
);

use Exporter 'import';
use Getopt::Long;
use File::Temp qw/ tempfile /;
use Term::Prompt;
use YAML::XS qw(LoadFile);
use Text::Autoformat;

use Tajordomo::Common;
use Tajordomo::Grades;
use Tajordomo::Rc;
use Tajordomo::List;
use Tajordomo::HOP;

use strict;
use warnings;

sub _email {
    my ($template, $grade, $autoformat, $dry, $confirm, $quiet, $rubric_path, @recipients) = @_;

    if (!defined($rc{EMAIL_FROM})) {
	say2 "Please set EMAIL_FROM in the config file for sending email.";
	exit 1;
    }

    my $rawgrade;
    $rawgrade = LoadFile($grade) if $grade;
    process_grades($rubric_path, [ $rawgrade ]);

    open(my $fh, "<", $template) or die "Cannot open $template: $!";
    my @lines = <$fh>;
    close($fh) or die "Cannot close $template: $!";

    foreach my $g (@recipients) {
	my $names = join(" + ", map { $_->{name} } @$g);
	my @to = map { sprintf "$_->{name} $_->{surname} <$_->{email}>" } @$g;
	my $to = join(",\n\t", @to);
	my $team = $g->[0]->{tid};

	my $tmp = File::Temp->new(DIR => '.tajordomo', SUFFIX => '.mail') ||
	    die "Cannot create temp file: $!";

	print $tmp "From: $rc{EMAIL_FROM}\n";
	print $tmp "To: $to\n";
	print $tmp "Cc: $rc{EMAIL_CC}\n" if $rc{EMAIL_CC};
	my @c = @lines;
	foreach my $l (@c) {
	    $l =~ s/\$NAMES/$names/g;
	    $l =~ s/\$TEAM/$team/g;
	    if ($grade && $l =~ /\$\{([^}]+)\}/) {
		my $val;
		if ($1 =~ /total/i) {
		    $val = $rawgrade->{_TOTAL};
		} else {
		    my %tr = (
			'comm' => '_COMM',
			'score' => '_SCORE',
			);
		    my @fields = split(" ", $1);
		    $fields[-1] = $tr{$fields[-1]};
		    $val = hash_leaf($rawgrade, \@fields);
		    if ($val && $autoformat && $fields[-1] eq '_COMM') {
			$val = autoformat $val, { fill=>0 };
			# remove all trailing newlines
			$/ = "";
			chomp $val;
		    }
		}
		$l =~ s/\$\{[^}]+\}/$val/g;
	    }
	    print $tmp $l;
	}

	my $git = "git send-email --from='$rc{EMAIL_FROM}' ";
	if ($rc{EMAIL_CC}) {
	    $git .= "--cc='" . join("' --cc='", split(", ", $rc{EMAIL_CC})) . "' ";
	}
	if ($rc{EMAIL_SMTP_OPTION}) {
	    $git .= "--smtp-server-option='$rc{EMAIL_SMTP_OPTION}' ";
	}
	$git .= "--suppress-cc=all --no-chain-reply-to ";
	$git .= "--quiet " if $quiet;
	$git .= "--to='" . join("' --to='", @to) . "' ";
	$git .= '--dry-run ' if $dry;
	$git .= "$tmp";

	if ($confirm) {
	    print "Sending the following:\n---------\n";
	    _system("cat $tmp");
	    print "---------\n";
	    my $result = &prompt("y", "Are you sure you want to send the above?", "y/n", "n");
	    if ($result == 0) {
		exit 0;
	    }
	}

	_system($git);
    }
}

sub send_email {
    my ($template, $grade, $autoformat, $dry, $confirm, $quiet, $rubric_path, $per_user, $per_team, $query) = args();

    if ($per_user and $per_team) {
	say2 "Sending email to both users and teams is not supported; ",
	"choose only one option.";
	exit 1;
    }

    if (!$per_user and !$per_team) {
	say2 "Please specific the recipients with --user or --team";
	exit 1;
    }

    if (!$template) {
	say2 "Need email template (--template).";
	exit 1;
    }

    my @results = filter($query);

    my @filtered = ();
    if ($per_team) {
	my %seen = ();
	foreach (@results) {
	    my $team = $_->{tid};

	    # sending per-team emails to members of no teams doesn't make sense
	    if ($team) {
		$seen{$team} = [] if !$seen{$team};
		push @{ $seen{$team} }, $_;
	    }
	}
	@filtered = map { $seen{$_} } keys %seen;
    } else {
	@filtered = map { [ $_ ] } @results;
    }

    _email($template, $grade, $autoformat, $dry, $confirm, $quiet, $rubric_path, @filtered);
}

sub args {
    my $help = 0;
    my $users = 0;
    my $teams = 0;
    my $autoformat = 0;
    my $dry = 0;
    my $quiet = 0;
    my $confirm = 0;
    my $rubric_path;
    my $template;
    my $grade;

    GetOptions(
	'autoformat'	=> \$autoformat,
	'dry-run'	=> \$dry,
	'confirm'	=> \$confirm,
        'help|h'        => \$help,
	'grade=s'	=> \$grade,
	'quiet'		=> \$quiet,
        'rubric=s'      => \$rubric_path,
	'teams|t'	=> \$teams,
	'template=s'	=> \$template,
	'users|u'	=> \$users,
    ) or usage();
    usage() if $help;

    my $argv = join(" ", @ARGV);

    return ($template, $grade, $autoformat, $dry, $confirm, $quiet, $rubric_path, $users, $teams, $argv);
}

1;
