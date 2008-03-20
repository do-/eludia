package Eludia::Presentation::Skins::Dumper;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

################################################################################

sub options {
	return {
		no_presentation => 1,
	};
}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};

	return Dumper ({
		data    => $page -> {content},								
	}) if $_REQUEST {__d};

	$_REQUEST {__content_type} ||= 'application/octet-stream';

	$r -> headers_out -> {'Content-Disposition'} = "attachment;filename=$_REQUEST{type}_$_REQUEST{id}.txt"; 

	my $dump = Dumper ({
		request => \%_REQUEST,
		user    => $_USER,
		content => $page -> {content},								
	});
	$dump =~ s/\x0A/\x0D\x0A/g;
							
	return $dump;

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};

	return Dumper ({error => {
		message => $_REQUEST {error},
		field   => $page -> {error_field},
	}}) if $_REQUEST {__d};

}

################################################################################

sub draw_redirect_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};

	return Dumper ({redirect => {url => $page -> {url}}}) if $_REQUEST {__d};

}

################################################################################

sub lrt_print {

	my $_SKIN = shift;

	my $id = int (time * rand);
	$r -> print ("<span id='$id'>");
	$r -> print (@_);
	$r -> print ("</span>");
	$r -> print ($lrt_bar);	
	$r -> print (<<EOH);
	<script>
		document.getElementById ('$id').scrollIntoView (false);
	</script>
	</body></html>
EOH


}

################################################################################

sub lrt_println {

	my $_SKIN = shift;

	$_SKIN -> lrt_print (@_, '<br>');
	
}

################################################################################

sub lrt_ok {
	my $_SKIN = shift;
	my $color = $_[1] ? 'red' : 'yellow';
	my $label = $_[1] ? 'Îøèáêà' : 'ÎÊ';
	$_SKIN -> lrt_println ("$_[0] <font color='$color'><b>[$label]</b></font>");
}

################################################################################

sub lrt_start {

	my $_SKIN = shift;

	$|=1;
	
	$r -> content_type ('text/html; charset=windows-1251');
	$r -> send_http_header ();
	
	$_SKIN -> lrt_print (<<EOH);
		<html><BODY BGCOLOR='#000000' TEXT='#dddddd'><font face='Courier New'>
			<iframe name=invisible src="$_REQUEST{__uri}0.html" width=0 height=0 application="yes">
			</iframe>
EOH

}

################################################################################

sub lrt_finish {

	my $_SKIN = shift;

	my ($banner, $href) = @_;
	
	$_SKIN -> lrt_print (<<EOH);
	<script>
		alert ('$banner');
		document.location = '$href';
	</script>
	</body></html>
EOH

}

1;
