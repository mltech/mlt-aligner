sub load_axis {
	my ( $text, $st_aref, $len_aref, $token_stat_href, $tkn2snt_href,
		$mwu_maxlen )
	  = @_;

	my $token, %new_st, %tkn2snt;
	my $stno = 0;

	@lines = split( /\n/, $text );

	#print STDERR "Loading axis...";
	foreach (@lines) {

		#chomp;

		s/\s+/ /g;    # TODO: remove??
		push @$st_aref, $_; # TODO: replace by a counter, the arry is never used
		                    #@_ = split ' ',$_;
		@_ = split '\|', $_;

		#undef %new_st;

		$snt = $_;

		#$snt =~ s/ //g;
		$snt =~ s/[ \|]//g;
		$$len_aref[$stno] = length $snt;

=cmt
	foreach (@_) {
	    #s/\W/\\$&/g;
	    next if defined $xstop{$_};
	    $$token_stat_href{$_}++;
	    $$token_stat_href{TTAALL}++;
	    $$tkn2snt_href{$_}{$stno} = 1;
	    #$new_st{$_}++;
	}
=cut

		for ( $i = 0 ; $i <= $#_ ; $i++ ) {
			for ( $k = 0 ; $k < $mwu_maxlen ; $k++ ) {
				if ( $i + $k <= $#_ ) {
					$tok = "";
					for ( $j = 0 ; $j <= $k ; $j++ ) {
						$tok .= ( $j == 0 ? "" : " " ) . $_[ $i + $j ];
					}
					next if defined $xstop{$tok};
					$$token_stat_href{$tok}++;
					$$token_stat_href{TTAALL}++;
					$$tkn2snt_href{$tok}{$stno} = 1;
				}
			}
		}
		$stno++;
	}

	#print STDOUT "//a// $token_stat_href\n";
	#print STDOUT "//b// ".join("/",%$token_stat_href)."\n";
	close A;

	#print STDERR "done.\n";
	#print STDERR "Number of sentences: $stno\n";
}

sub load_xstop {
	local ( $xstop_fn, $xstop_href ) = @_;

	#print STDERR "Reading X stop list... $xstop_fn";
	open XS, "<$xstop_fn" || die "$0: Couldn't open $xstop_fn!\n";
	while (<XS>) {
		chomp;
		$$xstop_href{$_} = 1;
	}
	close XS;

	#print STDERR " done.\n";
}

sub load_dict {
	my ( $dict_fn, $xstop_href, $dict_href ) = @_;

	#print STDERR "Reading seed translation lexicon...";

	#unless (-e $dict_fn) { die "$0: Couldn't open $dict_fn!\n" }
	open D, "$dict_fn";
	binmode D, ":utf8";
	while (<D>) {
		chomp;
		if (/^(.+) <> (.+)$/) {
			$source      = $1;
			$translation = $2;
			$source      =~ tr/[A-Z]/[a-z]/;
			$source      =~ s/^\s+//;
			$source      =~ s/\s+$//;
			$translation =~ s/^\s+//;
			$translation =~ s/\s+$//;
			next if defined $$xstop_href{$source};

			#$translation =~ s/\W/\\$&/g;
			push @{ $dict{$source} }, $translation;

			#print "$source / $#{$dict{$source}} / $translation\n";
		}
		else {
			print STDERR "invalid dictionary entry:\n$_\n";
		}
	}
	close D;

	#print STDERR " done.\n";
	#print STDERR "Number of entries: ", scalar keys %dict, "\n";
}

1;
