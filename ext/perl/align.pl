#use strict;
$|++;
binmode STDOUT, ":utf8";
binmode STDIN, ":utf8";

require MLTSegmentAligner::Aligner;

for ( $i = 0 ; $i < $#ARGV ; $i += 2 ) {
	$ini{$ARGV[$i]} = $ARGV[$i + 1]; 
}
my $aligner = MLTSegmentAligner::Aligner->new(%ini);

while (<STDIN>) {
	chomp;
	$_ =~ s/<br\/>/\n/g;
	( $text1, $text2 ) = split( /\|\|\|\|/, $_ );
	pipeout( $aligner->parse( $text1, $text2 ) );
}

sub pipeout {
	my ($string) = @_;
	print "$string\n\0\n";
}

