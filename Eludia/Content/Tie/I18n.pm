no warnings;

sub i18n {

	$conf -> {lang}  ||= 'RUS';

	$_REQUEST {lang} ||= $_USER -> {lang} if $_USER;

	$_REQUEST {lang} ||= $preconf -> {lang} || $conf -> {lang}; # According to NISO Z39.53

	$conf -> {i18n} -> {$_REQUEST {lang}} -> {_page_title} ||= $conf -> {page_title};

	my %i18n = ();
	
	tie %i18n, Eludia::Tie::I18n, {
	
		lang => $_REQUEST {lang},
		
		over => $conf -> {i18n} -> {$_REQUEST {lang}},
		
	};
	
	return \%i18n;

}

package Eludia::Tie::I18n;

sub TIEHASH  {

	my ($package, $options) = @_;

	$options -> {lang} or die "LANG not defined\n";
	
	${"Eludia::Tie::I18n::$options->{lang}"} ||= eval "require Eludia::Content::Tie::I18n::$options->{lang}";
	
	$options -> {under} = ${"Eludia::Tie::I18n::$options->{lang}"};

	bless $options, $package;

}

sub FETCH {

	my ($options, $key) = @_;
	
	return 
		$options -> {over} -> {$key}
		|| $options -> {under} -> {$key}
		|| $key;

}

1;