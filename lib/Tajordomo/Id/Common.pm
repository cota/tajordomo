package Tajordomo::Id::Common;

@EXPORT = qw(
  match_ids
);

use Exporter 'import';

use Tajordomo::Common;
use Tajordomo::Rc;

use strict;
use warnings;

my %id_formats = (
    "uni" => 1,
);

sub valid_formats_text {
    return join(', ', keys %id_formats);
}

sub match_ids {
    if ($rc{ID_FORMAT} eq 'uni') {
	use Tajordomo::Id::Uni;
    } else {
	print STDERR "Invalid ID_FORMAT '", $rc{ID_FORMAT}, "'. ";
	say2 "Valid values: ", valid_formats_text, ". Aborting.";
	exit 1;
    }
    return _match_ids(@_);
}
