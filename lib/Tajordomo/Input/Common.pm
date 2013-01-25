package Tajordomo::Input::Common;

@EXPORT = qw(
  read_input
);

use Exporter 'import';
use List::MoreUtils qw/ uniq /;

use Tajordomo::Common;
use Tajordomo::Rc;

use strict;
use warnings;

my %input_formats = (
    "mbox_dir" => 1,
);

sub valid_formats_text {
    return join(', ', keys %input_formats);
}

sub read_input {
    if ($rc{INPUT_FORMAT} eq 'mbox_dir') {
	use Tajordomo::Input::Mbox_dir;
    } else {
	print STDERR "Invalid INPUT_FORMAT '", $rc{ID_FORMAT}, "'. ";
	say2 "Valid values: ", valid_formats_text, ". Aborting.";
	exit 1;
    }
    return map { [ uniq @$_ ] } _read_input(@_);
}
