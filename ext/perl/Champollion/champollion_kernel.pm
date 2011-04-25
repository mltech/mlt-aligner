my $MINS = -10;

sub set_score {
	my ( $x, $y, $d ) = @_;

	$score{"$x,$y"} = $d;
}

sub get_score {
	my ( $x, $y ) = @_;

	if ( defined $score{"$x,$y"} ) {
		return $score{"$x,$y"};
	}
	else {
		return 0;
	}
}

sub align {
	my ( $x, $y, $nx, $ny, $logFile ) = @_;
	my ( $s1, $s2, $s3, $s4, $s5, $s6, $s7, $s8, $s9, $s10, $s11, $s12 );
	my ( $i,   $j,   $oi,  $oj,  $si,  $sj,  $smax );
	my ( $im1, $im2, $im3, $im4, $jm1, $jm2, $jm3, $jm4 );

	$xyratio = $nx / $ny;
	for ( $j = 0 ; $j <= $ny ; $j++ ) {
		my $center = int( $j * $xyratio );
		$window_start = $center - $window_size > 0 ? $center - $window_size : 0;
		$window_end = $center + $window_size < $nx ? $center + $window_size : $nx;

		#print "$window_start $window_end\n";
		for ( $i = $window_start ; $i <= $window_end ; $i++ ) {

			#$s1=$s2=$s3=$s4=$s5=$s6=$s7=$s8=$s9=$s10=$s11=$s12=-100;
			$im1 = $i - 1;
			$im2 = $i - 2;
			$im3 = $i - 3;
			$im4 = $i - 4;
			$jm1 = $j - 1;
			$jm2 = $j - 2;
			$jm3 = $j - 3;
			$jm4 = $j - 4;
#println("=> $i $j");
			$s1 = $i > 0 && $j > 0
			  ?    # 1-1
			  get_score( $i - 1, $j - 1 ) + match_sentences("$im1 - $jm1")
			  : $MINS;
			$s2 = $i > 0
			  ?    # 1-0
			  get_score( $i - 1, $j ) + match_sentences("$im1 -")
			  : $MINS;
			$s3 = $j > 0
			  ?    # 0-1
			  get_score( $i, $j - 1 ) + match_sentences("- $jm1")
			  : $MINS;
			$s4 = $i > 1 && $j > 0
			  ?    # 2-1
			  get_score( $i - 2, $j - 1 ) + match_sentences("$im2 $im1 - $jm1")
			  : $MINS;
			$s5 = $i > 0 && $j > 1
			  ?    # 1-2
			  get_score( $i - 1, $j - 2 ) + match_sentences("$im1 - $jm2 $jm1")
			  : $MINS;
			$s6 = $i > 1 && $j > 1
			  ?    # 2-2
			  get_score( $i - 2, $j - 2 ) +
			  match_sentences("$im2 $im1 - $jm2 $jm1")
			  : $MINS;

			unless ($disallow3) {
				$s7 = $i > 0 && $j > 2
				  ?    # 1-3
				  get_score( $i - 1, $j - 3 ) +
				  match_sentences("$im1 - $jm3 $jm2 $jm1")
				  : $MINS;
				$s8 = $i > 2 && $j > 0
				  ?    # 3-1
				  get_score( $i - 3, $j - 1 ) +
				  match_sentences("$im3 $im2 $im1 - $jm1")
				  : $MINS;
				$s9 = $i > 1 && $j > 2
				  ?    # 2-3
				  get_score( $i - 2, $j - 3 ) +
				  match_sentences("$im2 $im1 - $jm3 $jm2 $jm1")
				  : $MINS;
				$s10 = $i > 2 && $j > 1
				  ?    # 3-2
				  get_score( $i - 3, $j - 2 ) +
				  match_sentences("$im3 $im2 $im1 - $jm2 $jm1")
				  : $MINS;

#		$s11 = $i>2 && $j>2 ?               # 3-3
#		    get_score($i-3, $j-3) + match_sentences("$im3 $im2 $im1 - $jm3 $jm2 $jm1")
#			: $MINS;
				$s12 = $i > 0 && $j > 3
				  ?    # 1-4
				  get_score( $i - 1, $j - 4 ) +
				  match_sentences("$im1 - $jm4 $jm3 $jm2 $jm1")
				  : $MINS;
				$s13 = $i > 3 && $j > 0
				  ?    # 4-1
				  get_score( $i - 4, $j - 1 ) +
				  match_sentences("$im4 $im3 $im2 $im1 - $jm1")
				  : $MINS;
			}

			$smax = $s1;
			if ( $s2 > $smax )  { $smax = $s2 }
			if ( $s3 > $smax )  { $smax = $s3 }
			if ( $s4 > $smax )  { $smax = $s4 }
			if ( $s5 > $smax )  { $smax = $s5 }
			if ( $s6 > $smax )  { $smax = $s6 }
			if ( $s7 > $smax )  { $smax = $s7 }
			if ( $s8 > $smax )  { $smax = $s8 }
			if ( $s9 > $smax )  { $smax = $s9 }
			if ( $s10 > $smax ) { $smax = $s10 }

			#if($s11>$smax) { $smax=$s11 };
			if ( $s12 > $smax ) { $smax = $s12 }
			if ( $s13 > $smax ) { $smax = $s13 }

			if ( $smax == $MINS ) {
				set_score( $i, $j, 0 );
			}
			elsif ( $smax == $s1 ) {    # 1-1
				set_score( $i, $j, $s1 );
				$path_x{"$i,$j"} = $i - 1;
				$path_y{"$i,$j"} = $j - 1;
			}
			elsif ( $smax == $s2 ) {    # 1-0
				set_score( $i, $j, $s2 );
				$path_x{"$i,$j"} = $i - 1;
				$path_y{"$i,$j"} = $j;
			}
			elsif ( $smax == $s3 ) {    # 0-1
				set_score( $i, $j, $s3 );
				$path_x{"$i,$j"} = $i;
				$path_y{"$i,$j"} = $j - 1;
			}
			elsif ( $smax == $s4 ) {    # 2-1
				set_score( $i, $j, $s4 );
				$path_x{"$i,$j"} = $i - 2;
				$path_y{"$i,$j"} = $j - 1;
			}
			elsif ( $smax == $s5 ) {    # 1-2
				set_score( $i, $j, $s5 );
				$path_x{"$i,$j"} = $i - 1;
				$path_y{"$i,$j"} = $j - 2;
			}
			elsif ( $smax == $s6 ) {    # 2-2
				set_score( $i, $j, $s6 );
				$path_x{"$i,$j"} = $i - 2;
				$path_y{"$i,$j"} = $j - 2;
			}
			elsif ( $smax == $s7 ) {    # 1-3
				set_score( $i, $j, $s7 );
				$path_x{"$i,$j"} = $i - 1;
				$path_y{"$i,$j"} = $j - 3;
			}
			elsif ( $smax == $s8 ) {    # 3-1
				set_score( $i, $j, $s8 );
				$path_x{"$i,$j"} = $i - 3;
				$path_y{"$i,$j"} = $j - 1;
			}
			elsif ( $smax == $s9 ) {    # 2-3
				set_score( $i, $j, $s9 );
				$path_x{"$i,$j"} = $i - 2;
				$path_y{"$i,$j"} = $j - 3;
			}
			elsif ( $smax == $s10 ) {    # 3-2
				set_score( $i, $j, $s10 );
				$path_x{"$i,$j"} = $i - 3;
				$path_y{"$i,$j"} = $j - 2;

				#	    } elsif ($smax == $s11) {            # 3-3
				#		set_score($i,$j,$s11);
				#		$path_x{"$i,$j"} = $i-3;
				#		$path_y{"$i,$j"} = $j-3;
			}
			elsif ( $smax == $s12 ) {    # 1-4
				set_score( $i, $j, $s12 );
				$path_x{"$i,$j"} = $i - 1;
				$path_y{"$i,$j"} = $j - 4;
			}
			elsif ( $smax == $s13 ) {    # 4-1
				set_score( $i, $j, $s13 );
				$path_x{"$i,$j"} = $i - 4;
				$path_y{"$i,$j"} = $j - 1;
			}
			print("** $smax\t\t\t-> $i|".$path_x{"$i,$j"}." $j|".$path_y{"$i,$j"}." // $s1:$s2:$s3:$s4:$s5:$s6:$s7:$s8:$s9:$s10:$s11:$s12:$s13\n");
		}
		
	}

	#print STDERR "Writing alignement scores to file $logFile...\n";
	open LOGFILE, ">$logFile";
	$n = 0;
	for ( $i = $nx, $j = $ny ; $i > 0 || $j > 0 ; $i = $oi, $j = $oj, $n++ ) {
		$oi = $path_x{"$i,$j"};
		$oj = $path_y{"$i,$j"};
		$si = $i - $oi;
		$sj = $j - $oj;

		$im1 = $i - 1;
		$im2 = $i - 2;
		$im3 = $i - 3;
		$jm1 = $j - 1;
		$jm2 = $j - 2;
		$jm3 = $j - 3;

		if ( $si == 1 && $sj == 1 ) {    # 1-1
			$ralign[$n] = "$i <=> $j";
		}
		elsif ( $si == 1 && $sj == 0 ) {    # 1-0
			$ralign[$n] = "$i <=> omitted";
		}
		elsif ( $si == 0 && $sj == 1 ) {    # 0-1
			$ralign[$n] = "omitted <=> $j";
		}
		elsif ( $si == 2 && $sj == 1 ) {    # 2-1
			$ralign[$n] = "$im1,$i <=> $j";
		}
		elsif ( $si == 1 && $sj == 2 ) {    # 1-2
			$ralign[$n] = "$i <=> $jm1,$j";
		}
		elsif ( $si == 2 && $sj == 2 ) {    # 2-2
			$ralign[$n] = "$im1,$i <=> $jm1,$j";
		}
		elsif ( $si == 1 && $sj == 3 ) {    # 1-3
			$ralign[$n] = "$i <=> $jm2,$jm1,$j";
		}
		elsif ( $si == 3 && $sj == 1 ) {    # 3-1
			$ralign[$n] = "$im2,$im1,$i <=> $j";
		}
		elsif ( $si == 2 && $sj == 3 ) {    # 2-3
			$ralign[$n] = "$im1,$i <=> $jm2,$jm1,$j";
		}
		elsif ( $si == 3 && $sj == 2 ) {    # 3-2
			$ralign[$n] = "$im2,$im1,$i <=> $jm1,$j";

			#	} elsif ($si == 3 && $sj == 3) {          # 3-3
			#	    $ralign[$n] = "$im2,$im1,$i <=> $jm2,$jm1,$j";
		}
		elsif ( $si == 1 && $sj == 4 ) {    # 1-4
			$ralign[$n] = "$i <=> $jm3,$jm2,$jm1,$j";
		}
		elsif ( $si == 4 && $sj == 1 ) {    # 4-1
			$ralign[$n] = "$im3,$im2,$im1,$i <=> $j";
		}
		# TODO: performance logging
		#print LOGFILE $ralign[$n] . "\t" . get_score( $i, $j ) . "\n";
		
		
		$ralign[$n] .= "\t" . get_score( $i, $j );
		

		#print STDERR "xxx ".$ralign[$n]."\t".get_score($i, $j)."\n";
	}
	close LOGFILE;
	return $n;
}

sub match_sentences {
	my ($map) = @_;
	my ( $score, $x, $y, @x, @y, $nx, $ny, $xlen, $ylen );
	my $length_penalty = 1;

	( $x, $y ) = split '-', $map;

	#print STDERR "--- $map ---\n";
	@x = split ' ', $x;
	@y = split ' ', $y;

	$nx = @x;
	$ny = @y;

	#print STDERR "FS: -0.01\n";
	return -0.1 if $nx == 0 || $ny == 0;

	# faster implementation
	if ($fast) {
		if ( $nx == 1 && $ny == 1 ) {
			$score = score11( @x, @y );
		}
		elsif ( $nx == 1 && $ny == 2 ) {
			$score = score12( @x, @y );
		}
		elsif ( $nx == 2 && $ny == 1 ) {
			$score = score12( @x, @y );
		}
		elsif ( $nx == 2 && $ny == 2 ) {
			$score = score12( @x, @y );
		}
		elsif ( $nx == 1 && $ny == 3 ) {
			$score = score13( @x, @y );
		}
		elsif ( $nx == 3 && $ny == 1 ) {
			$score = score31( @x, @y );
		}
		elsif ( $nx == 2 && $ny == 3 ) {
			$score = score23( @x, @y );
		}
		elsif ( $nx == 3 && $ny == 2 ) {
			$score = score32( @x, @y );
		}
		elsif ( $nx == 3 && $ny == 3 ) {
			$score = score33( @x, @y );
		}
		elsif ( $nx == 1 && $ny == 4 ) {
			$score = score14( @x, @y );
		}
		elsif ( $nx == 4 && $ny == 1 ) {
			$score = score41( @x, @y );
		}

		# slower implementation
	}
	else {
		$xsentences = merge_sentences( \@xst, @x );
		$ysentences = merge_sentences( \@yst, @y );
		$score      =
		  match_sentences_lex( \@x, \@y, $xsentences, $ysentences,
			\%xtoken_stat );
	}

	foreach (@x) {
		$xlen += $lenx[$_];
	}

	foreach (@y) {
		$ylen += $leny[$_];
	}

	if ( max( $xlen, $ylen / $xtoyc ) > 60 ) {
		$length_penalty =
		  log(
			6 + 4 * min( $xlen * $xtoyc, $ylen ) / max( $xlen * $xtoyc, $ylen )
		  ) / log(10);
	}

	if ( $nx == 1 && $ny == 1 ) {
		return $score * $length_penalty;
	}
	elsif ( $nx == 1 && $ny == 2 ) {
		return $score * $length_penalty * $penalty12;
	}
	elsif ( $nx == 2 && $ny == 1 ) {
		return $score * $length_penalty * $penalty21;
	}
	elsif ( $nx == 2 && $ny == 2 ) {
		return $score * $length_penalty * $penalty22;
	}
	elsif ( $nx == 1 && $ny == 3 ) {
		return $score * $length_penalty * $penalty13;
	}
	elsif ( $nx == 3 && $ny == 1 ) {
		return $score * $length_penalty * $penalty31;
	}
	elsif ( $nx == 2 && $ny == 3 ) {
		return $score * $length_penalty * $penalty23;
	}
	elsif ( $nx == 3 && $ny == 2 ) {
		return $score * $length_penalty * $penalty32;
	}
	elsif ( $nx == 3 && $ny == 3 ) {
		return $score * $length_penalty * $penalty33;
	}
	elsif ( $nx == 1 && $ny == 4 ) {
		return $score * $length_penalty * $penalty14;
	}
	elsif ( $nx == 4 && $ny == 1 ) {
		return $score * $length_penalty * $penalty41;
	}
}

sub match_sentences_lex {

	my (
		$xsnts_index,    $ysnts_index, $xsentences_ref,
		$ysentences_ref, $xtoken_stat_href
	  )
	  = @_;
	my ( %xtokens, %ytokens );
	my $min_pairs = 1, $score = 0;

	#print ":* $mwu_maxlen_x $mwu_maxlen_y\n";

	@_ = split '\|', $$xsentences_ref;
 
	#=cmt
	for ( $i = 0 ; $i <= $#_ ; $i++ ) {
		for ( $k = 0 ; $k < $mwu_maxlen_x ; $k++ ) {
			if ( $i + $k <= $#_ ) {
				$tok = "";
				for ( $j = 0 ; $j <= $k ; $j++ ) {
					$tok .= ( $j == 0 ? "" : " " ) . $_[ $i + $j ];
				}
				$xtokens{$tok}++;
			}
		}
	}

	#=cut

=cmt
    foreach (@_) {
	$xtokens{$_}++;
    }
=cut

	@_ = split '\|', $$ysentences_ref;

	#=cmt
	for ( $i = 0 ; $i <= $#_ ; $i++ ) {
		for ( $k = 0 ; $k < $mwu_maxlen_y ; $k++ ) {
			if ( $i + $k <= $#_ ) {
				$tok = "";
				for ( $j = 0 ; $j <= $k ; $j++ ) {
					$tok .= ( $j == 0 ? "" : " " ) . $_[ $i + $j ];
				}
				$ytokens{$tok}++;
			}
		}
	}
#print "*** ".join("*", %ytokens);
	#=cut

=cmt
    foreach (@_) {
	$ytokens{$_}++;
    }
=cut

	#print STDERR "score bag words\n";

	$x_total_tokens = $$xtoken_stat_href{"TTAALL"};

 # print STDERR "\n\n", join ' ',@$xsnts_index,"-", join ' ',@$ysnts_index,"\n";
	foreach $xtoken ( keys %xtokens ) {

		if ( defined $ytokens{$xtoken} && !defined $xstop{$xtoken} ) {
#print "#1# $xtoken / $#{$dict{$xtoken}}\n";
			#print STDOUT " 0-> $xtoken $xtoken_trans $ytokens{$xtoken_trans}\n";

			$score +=
			  log( ( $x_total_tokens / $$xtoken_stat_href{$xtoken} ) *
				  min( $xtokens{$xtoken}, $ytokens{$xtoken} ) + 1 );
		}
		else {
#print "#2# $xtoken / $#{$dict{$xtoken}}\n";
			foreach $xtoken_trans ( @{ $dict{$xtoken} } ) {
			#print STDOUT " 1-> $xtoken/$xtoken_trans/$ytokens{$xtoken_trans}/$#ytokens\n";

				if ( defined $ytokens{$xtoken_trans} ) {
#print "#3# $xtoken / $#{$dict{$xtoken}}\n";
					$min_pairs =
					  min( $xtokens{$xtoken}, $ytokens{$xtoken_trans} );
					next if $min_pairs == 0;
#print ("---> $xtoken/$x_total_tokens/".$$xtoken_stat_href{$xtoken}."\n");
					$score +=
					  log( ( $x_total_tokens / $$xtoken_stat_href{$xtoken} ) *
						  $min_pairs + 1 );
					$xtokens{$xtoken}       -= $min_pairs;
					$ytokens{$xtoken_trans} -= $min_pairs;
					last;
				}
			}
		}
	}

	#print STDERR "Score: $score\n";
	return $score;
}

sub merge_sentences {
	my ( $st_aref, @st ) = @_;
	my ($sentences);

	# merge one sentence
	if ( scalar @st == 1 ) {
		$sentences = $$st_aref[ $st[0] ];

		# merge two sentences
	}
	elsif ( scalar @st == 2 ) {
		$sentences = "$$st_aref[$st[0]] $$st_aref[$st[1]]";

		# merge three sentences
	}
	elsif ( scalar @st == 3 ) {
		$sentences = "$$st_aref[$st[0]] $$st_aref[$st[1]] $$st_aref[$st[2]]"

		  # merge four sentences
	}
	elsif ( scalar @st == 4 ) {
		$sentences =
"$$st_aref[$st[0]] $$st_aref[$st[1]] $$st_aref[$st[2]] $$st_aref[$st[3]]";
	}

	return \$sentences;

}

sub score11 {
	local ( $x1, $y1 ) = @_;

	return $st_scores{"$x1,$y1"};
}

sub score12 {
	local ( $x1, $y1, $y2 ) = @_;

	return $st_scores{"$x1,$y1"} + $st_scores{"$x1,$y2"};
}

sub score21 {
	local ( $x1, $x2, $y1 ) = @_;

	return $st_scores{"$x1,$y1"} + $st_scores{"$x2, $y1"};
}

sub score22 {
	local ( $x1, $x2, $y1, $y2 ) = @_;
	return $st_scores{"$x1,$y1"} + $st_scores{"$x1,$y2"} +
	  $st_scores{"$x2,$y1"} + $st_scores{"$x2,$y1"};
}

sub score31 {
	local ( $x1, $x2, $x3, $y1 ) = @_;
	return $st_scores{"$x1,$y1"} + $st_scores{"$x2,$y1"} +
	  $st_scores{"$x3,$y1"};
}

sub score13 {
	local ( $x1, $y1, $y2, $y3 ) = @_;
	return $st_scores{"$x1,$y1"} + $st_scores{"$x1,$y2"} +
	  $st_scores{"$x1,$y3"};
}

sub score41 {
	local ( $x1, $x2, $x3, $x4, $y1 ) = @_;
	return $st_scores{"$x1,$y1"} + $st_scores{"$x2,$y1"} +
	  $st_scores{"$x3,$y1"} + $st_scores{"$x4,$y1"};
}

sub score14 {
	local ( $x1, $y1, $y2, $y3, $y4 ) = @_;
	return $st_scores{"$x1,$y1"} + $st_scores{"$x1,$y2"} +
	  $st_scores{"$x1,$y3"} + $st_scores{"$x1,$y4"};
}

sub score14 { }
sub score23 { }
sub score32 { }
sub score33 { }

1;

