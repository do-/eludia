################################################################################

sub dump_attributes {
		
	my $html = ' ';
	
	foreach my $k (keys %{$_[0]}) { 
		$v = $_[0] -> {$k};
		next if $v eq '';
		$html .= ' ';
		$html .= $k;
		$html .= "='";
		$v =~ s{\'}{&#39;}g; #'
		$html .= $v;
		$html .= "'";
	}
	
	return $html;
	
}

################################################################################

sub dump_tag {

	my ($tag, $attributes, $value) = @_;

	my $html = "<$tag";
		
	$html .= dump_attributes ($attributes) if $attributes;
	
	$html .= '>';
	
	$value or return $html;
	
	$html .= "$value</$tag>";
	
	return $html;

}

################################################################################

BEGIN {
	
	$preconf -> {_} -> {presentation_tools} = 'PP';
		
	print STDERR "Pure Perl, ok.\n";
	
}

1;