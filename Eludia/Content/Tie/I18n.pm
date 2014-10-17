no warnings;

sub i18n {

	$conf -> {lang}  ||= 'RUS';

	$_REQUEST {lang} ||= $_USER -> {lang} if $_USER;

	$_REQUEST {lang} ||= $preconf -> {lang} || $conf -> {lang}; # According to NISO Z39.53

	$conf -> {i18n} -> {$_REQUEST {lang}} -> {_page_title} ||= $conf -> {page_title};

	our $_ACTIONS ||= {_actions => {}};
	our $_I18N_TYPES ||= {};

	my %i18n = ();
warn "Tie i18n: " . $_REQUEST {lang};
	tie %i18n, Eludia::Tie::I18n, {

		lang => $_REQUEST {lang},

		over => [$_ACTIONS, $_I18N_TYPES, $conf -> {i18n} -> {$_REQUEST {lang}}],

	};

	return bless \%i18n, 'Eludia::Tie::I18n';

}

package Eludia::Tie::I18n;
use Data::Dumper;

sub lc {&{$_[0] -> {_subs} -> {lc}} ($_[1])};

sub uc {&{$_[0] -> {_subs} -> {uc}} ($_[1])};

sub ucfirst {

	my ($self, $s) = @_;

	$self -> uc (substr ($s, 0, 1)) .

	substr ($s, 1)

};

sub ucfirstlcrest {

	my ($self, $s) = @_;

	$self -> uc (substr ($s, 0, 1)) .

	$self -> lc (substr ($s, 1))

};

sub TIEHASH  {

	my ($package, $options) = @_;

	$options -> {lang} or die "LANG not defined\n";

	unless (${"Eludia::Tie::I18n::$options->{lang}"}) {

		${"Eludia::Tie::I18n::$options->{lang}"} = eval "require Eludia::Content::Tie::I18n::$options->{lang}";
		if ($options -> {lang} =~ /UTF/i) {
			my $hash  = Dumper (\%{${"Eludia::Tie::I18n::$options->{lang}"}});
			$hash =~ s/^\$VAR1 = //;
			eval qq |use utf8; \${"Eludia::Tie::I18n::$options->{lang}"} = $hash|;
		}
	}

	$options -> {under} = ${"Eludia::Tie::I18n::$options->{lang}"};

	$options -> {under} -> {_subs} -> {'lc'} = eval qq {

		sub {

			my (\$s) = \@_;

			\$s =~ y/$options->{under}->{_uc}/$options->{under}->{_lc}/;

			return \$s;

		}

	};

	$options -> {under} -> {_subs} -> {'uc'} = eval qq {

		sub {

			my (\$s) = \@_;

			\$s =~ y/$options->{under}->{_lc}/$options->{under}->{_uc}/;

			return \$s;

		}

	};

	bless $options, $package;

}

sub FETCH {

	my ($options, $key) = @_;

	foreach my $over (@{$options -> {over}}) {

		return $over -> {$key} if $over -> {$key};

	}

	return $options -> {under} -> {$key} || $key;

}

1;