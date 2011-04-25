package MLTSegmentAligner::Aligner;

use utf8;
use Cwd;

my $docId;
my $champollion_path;
my $file;
my %dict;
our $xtoyc;
our $mwu_maxlen_x;
our $mwu_maxlen_y;

our $penalty01;
our $penalty21;
our $penalty12;
our $penalty22;
our $penalty31;
our $penalty13;
our $penalty32;
our $penalty23;
our $penalty41;
our $penalty14;

sub new
{
	($proto, %ini) = @_;
	my $class = ref($proto) || $proto;
	my $self  = {};
	
#	CHANGE iniParam to hash - directly generated from command line params

    #while( my ($k, $v) = each %ini ) {
    #    print "key: $k, value: $v.\n";
    #}
	
	$penalty01 = $ini{"penalty01"};
	$penalty21 = $ini{"penalty21"};
	$penalty12 = $ini{"penalty12"};
	$penalty22 = $ini{"penalty22"};
	$penalty31 = $ini{"penalty31"};
	$penalty13 = $ini{"penalty13"};
	$penalty32 = $ini{"penalty32"};
	$penalty23 = $ini{"penalty23"};
	$penalty41 = $ini{"penalty41"};
	$penalty14 = $ini{"penalty14"};
	$xtoyc = $ini{"xtoyc"};

	push @INC, getcwd."/ext/perl/Champollion";
	require "load_functions.pm";
	require "len_match.pl";
	require "champollion_kernel.pm";

	if ($ini{"usedict"} eq "yes")
	{
		load_xstop($ini{"stoplistpath"}, \%xstop);
		load_dict($ini{"dictpath"}, \%xstop, \%dict);
	}

	$mwu_maxlen_x = 1;#$ini{"mwu_maxlen_x"}; //TODO: take from config file / chek if min val = 1
	$mwu_maxlen_y = 1;#$ini{"mwu_maxlen_y"};

	bless($self, $class);
	return $self;
}

sub parse
{
	my ($self, $text1, $text2) = @_;

	my @source_lines;
	my @dest_lines;
	my $chmp;
			
	#$workingDir = $self->workingDir;
	return join("\n", champollion($text1, $text2));
	
=cmt
	@text1_lines = split(/\n/, $text1);
	@text2_lines = split(/\n/, $text2);
	
	$anum = 0;
	foreach $line (champollion($text1, $text2))
	{
		$anum++;
		if ($line !~ /omitted/)
		{
			split(/ <=> /, $line);
			foreach $num (split(/,/, $_[0]))
			{
				$num--;
				$text1_lines[$num] =~ s/\n//g;
				print STDOUT $text1_lines[$num]." ";
			}
			print STDOUT "\n";
			$snum = 0;
			foreach $num (split(/,/, $_[1]))
			{
				$num--;
				$text2_lines[$num] =~ s/\n//g;
				print STDOUT $text2_lines[$num]." ";
			}
			print STDOUT "\n\n";
		}
	}
=cut
}

sub champollion
{
	($enDoc, $jpDoc, $logFile) = @_;
	
	$enDoc =~ /(.*)[^\.]*/;

	# TODO: change load_axis to take the strings, not the files as params
	load_axis($enDoc, \@xst, \@lenx, \%xtoken_stat, \%xtkn2snt, $mwu_maxlen_x);
	load_axis($jpDoc, \@yst, \@leny, \%ytoken_stat, \%ytkn2snt, $mwu_maxlen_y);

	$nx = @xst;
	$ny = @yst;
#print join( "::", @xst)."//".join("::", @yst);
#exit;
	$xyratio = $nx/$ny;

	$WIN_PER_100 = 8;
	$MIN_WIN_SIZE = 10;
	$MAX_WIN_SIZE = 600;
	$w1_size = int($xyratio*$nx*$WIN_PER_100/100);
	$w2_size = int(abs($nx-$ny)*3/4);
	$window_size = min(max($MIN_WIN_SIZE,max($w1_size,$w2_size)),$MAX_WIN_SIZE);
	#print STDERR "Window size: $window_size\n";
	
	#print STDERR "Aligning Sentences ... ";
	align(\@lenx, \@leny, $nx, $ny, $logFile);
	#print STDERR "done.\n";

	# If all sentences are translated
	if ($alignall)
	{
	    merge_omission();
	}
	
	#print_alignment($out);
	@ret = reverse @ralign;
		
	undef @xst;
	undef @lenx;
	undef %xtoken_stat;
	undef %xtkn2snt;
	undef @yst;
	undef @leny; 
	undef %ytoken_stat;
	undef %ytkn2snt;
	undef %x2ymap;
	undef @x;
	undef @y;
	undef %xtoken_stat;
	undef @ralign;
	
	#open RET, ">$enDoc.chmp.txt";
	#print RET join("\n", @ret);
	#close RET;
	
	return @ret;
}

sub merge_omission {
    my ($xalign_tkn, $yalign_tkn, $xyratio);
    my (%x2ymap, %y2xmap);
    my (@align_org, @align);

    @align_org = reverse @ralign;

    $i = 0;
    $x2ymap{0} = [0];
    $y2xmap{0} = [0];
    $xfnp1 = $xfn+1;
    $yfnp1 = $yfn+1;
    $x2ymap{$xfnp1} = [$yfnp1];
    $y2xmap{$yfnp1} = [$xfnp1];
    foreach (@align_org) {
	$index{$_} = $i; $i++;
	next if /omitted/;
	/(.+) <=> (.+)/;
	$xsent = $1; $ysent = $2;
	@xsent = split /,/, $xsent;
	@ysent = split /,/, $ysent;
	foreach (@xsent) {
	    $xalign_tkn += $lenx[$_-1];
	    $x2ymap{$_} = [@ysent];
	}
	foreach (@ysent) {
	    $yalign_tkn += $leny[$_-1];
	    $y2xmap{$_} = [@xsent];
	}
    }
    
    $xyratio = $xalign_tkn/$yalign_tkn;

    for ($i = 0; $i<@align_org; $i++) {
	next unless $align_org[$i] =~ /omitted/;

	if ($align_org[$i] =~ /omitted <=> (\d+)/) {
	    $ysid = $1;
	    $lb = lowerbound($ysid, \%y2xmap);
	    $ub = upperbound($ysid, \%y2xmap);
	    #print STDERR "UB: $ub LB: $lb\n";
	    next unless defined $ub && defined $lb;
	    if ($ub-$lb == 2) {
		$xsid = $lb+1;
		$align_org[$i] = "$xsid <=> $ysid";
		$align_org[$index{"$xsid <=> omitted"}] = "";
	    } elsif ($ub-$lb == 1) {
		my ($pxtkn, $pytkn, $nxtkn, $nytkn);
		
		# counting tokens of previous alignment
		$align_org[$i-1] =~ /(.+) <=> (.+)/;
		$xsent = $1; $ysent = $2;
		@xsent = split /,/, $xsent;
		@ysent = split /,/, $ysent;
		foreach (@xsent) {
		    $pxtkn += $lenx[$_-1];
		}
		foreach (@ysent) {
		    $pytkn += $leny[$_-1];
		}

		# counting tokens of next alignment
		$align_org[$i+1] =~ /(.+) <=> (.+)/;
		$xsent = $1; $ysent = $2;
		@xsent = split /,/, $xsent;
		@ysent = split /,/, $ysent;
		foreach (@xsent) {
		    $nxtkn += $lenx[$_-1];
		}
		foreach (@ysent) {
		    $nytkn += $leny[$_-1];
		}
		if ($pxtkn/$pytkn > $nxtkn/$nytkn) {
		    $align_org[$i-1] .= ",$ysid";
		} else {
		    $align_org[$i+1] =~ s/<=> /<=> $ysid,/;
		}
		$align_org[$i] = "";
	    }
	} elsif ($align_org[$i] =~ /(\d+) <=> omitted/) {
	    $xsid = $1;
	    $lb = lowerbound($xsid, \%x2ymap);
	    $ub = upperbound($xsid, \%x2ymap);
	    next unless defined $ub && defined $lb;
	    if ($ub-$lb == 1) {
		my ($pxtkn, $pytkn, $nxtkn, $nytkn) = (0,0,0,0);
		
		# counting tokens of previous alignment
		$align_org[$i-1] =~ /(.+) <=> (.+)/;
		$xsent = $1; $ysent = $2;
		@xsent = split /,/, $xsent;
		@ysent = split /,/, $ysent;
		foreach (@xsent) {
		    $pxtkn += $lenx[$_-1];
		}
		foreach (@ysent) {
		    $pytkn += $leny[$_-1];
		}

		# counting tokens of next alignment
		$align_org[$i+1] =~ /(.+) <=> (.+)/;
		$xsent = $1; $ysent = $2;
		@xsent = split /,/, $xsent;
		@ysent = split /,/, $ysent;
		foreach (@xsent) {
		    $nxtkn += $lenx[$_-1];
		}
		foreach (@ysent) {
		    $nytkn += $leny[$_-1];
		}

		if ($pxtkn/$pytkn < $nxtkn/$nytkn) {
		    $align_org[$i-1] =~ s/ <=>/,$xsid <=>/;
		} else {
		    $align_org[$i+1] = $xsid.",".$align_org[$i+1];
		}
		$align_org[$i] = "";
	    }
	}
    }
    undef @ralign;
    foreach (@align_org) {
	push @ralign, $_ unless /^$/;
    }
    
    @ralign = reverse @ralign;
    
}

sub print_alignment {
    my ($align_fn) = @_;

    open A, ">$align_fn" || die;
    foreach (reverse @ralign) {
	print A "$_\n";
    }
    close A;
}

sub min {
    local ($x, $y) = @_;

    return $x<$y?$x:$y;
}

sub max {
    local ($x, $y) = @_;

    return $x>$y?$x:$y;
}
1;
