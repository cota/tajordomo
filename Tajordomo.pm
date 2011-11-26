#!/usr/bin/perl
# Tajordomo common helpers are grouped here

use warnings;
use strict;

package Tajordomo;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    read_students_list
    $course_shortname
    );

our $course_shortname = '4824';

# Format of the input file
# Name\tSurname\tUNI@dontcare
# A UNI is [a-z]{2,3}[0-9]{4}.
sub read_students_list
{
    my ($filename) = @_;
    my %students;

    open(my $fh, "<", $filename) or die("cannot open $filename");
    while (<$fh>) {
	chomp;

	my @fields = split("\t");
	if (@fields) {
	    my $email = $fields[2];
	    $email =~ m/([^@]+)@.*/;
	    my $uni = $1;

	    $students{$uni}->{email} = $email;
	    $students{$uni}->{name} = $fields[0];
	    $students{$uni}->{surname} = $fields[1];
	}
    }
    close($fh) or die("Cannot close $filename");

    return \%students;
}
