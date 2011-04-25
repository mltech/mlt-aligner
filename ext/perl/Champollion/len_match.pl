#!/usr/bin/perl

#while(<>){
#    chomp;
#    if (/^(\d+) (\d+)$/) {
#	print match_sentences_len($1,$2,0.522,1.77),"\n";
#    }
#}


sub pnorm {
    my ($z) = @_;

    my $t = 1/(1+0.2316419*$z);
    my $pd = 1-0.3989423*exp(-$z*$z/2)*
	((((1.330274429*$t-1.821255978)*$t
	   +1.781477937)*$t-0.356563782)*$t+0.319381530)*$t;

    return $pd;
}

sub match_sentences_len {
    my ($len1,$len2, $y_chars_per_x_char, $var_per_x_char) = @_;

    if ($len1==0 && $len2==0) {
	return 0;
    }

    $mean = ($len1+$len2/$y_chars_per_x_char)/2;
    $z = ($y_chars_per_x_char*$len1-$len2)/sqrt($var_per_x_char*$mean);

    if ($z<0) {$z = -$z}

    $pd = 2*(1-pnorm($z));
    return $pd;
    #return 0.5+1-pnorm($z);
}

1;
