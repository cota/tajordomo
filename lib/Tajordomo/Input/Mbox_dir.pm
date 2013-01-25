package Tajordomo::Input::Mbox_dir;

@EXPORT = qw(
  _read_input
);

use Exporter 'import';

use Mail::Box::Manager;

use Tajordomo::Common;
use Tajordomo::Rc;
use Tajordomo::Id::Common;

use strict;
use warnings;

sub _read_input {
    my $mbox = shift;

    my $mgr = Mail::Box::Manager->new;
    my $folder = $mgr->open($mbox) || exit 1;
    my @raw_teams = ();

    foreach my $message ($folder->messages) {
	my $text;
	# discard multipart crap, such as HTML.
	if ($message->isMultipart) {
	    foreach my $part ($message->parts) {
		if ($part->contentType eq 'text/plain') {
		    $text = $part->decoded;
		}
	    }
	} else {
	    $text = $message->decoded;
	}

	my @ids = match_ids($text);
	if (@ids) {
	    push @raw_teams, \@ids;
	}
    }
    return @raw_teams;
}
