package Eludia::Presentation::Skins::JSONDumper;

################################################################################

sub options { return {no_presentation => 1}}

################################################################################

sub no_presentation { 1 }

################################################################################

sub draw_hash {

	my ($_SKIN, $h) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};

	$_JSON -> encode ($h);

}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__only_menu} and return $_SKIN -> draw_page_just_to_reload_menu ($page);

	$page -> {content} -> {__this_content_is_ok_to_be_shown_completely} or $page -> {content} = 'Sorry?..';

	return $_SKIN -> draw_hash ({

		content => $page -> {content},

	});

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;

	return $_SKIN -> draw_hash ({ 
	
		message => $_REQUEST {error},
		
		field   => $page -> {error_field},
		
	});

}

################################################################################

sub draw_redirect_page {

	my ($_SKIN, $page) = @_;

	return $_SKIN -> draw_hash ({ 
	
		url   => $page -> {url},
		
	});

}

################################################################################

sub _menu_item {

	my ($i) = @_;

	$i -> {label} =~ s{^\&}{};

	if ($i -> {no_page} || $i -> {items}) {
		$i -> {href} ||= "undefined";
	}
	else {
		$i -> {href} ||= "/?type=$i->{name}";
		$i -> {href}  .= "&sid=$_REQUEST{sid}"
			if $i -> {href} !~ /^http/;
	}

	$i -> {id} ||= $i -> {href} eq 'undefined'?
		Digest::MD5::md5_hex ($i -> {label})
		: $i -> {href};

	$i -> {id} =~ s{[\&\?]?sid\=\d+}{};
}

################################################################################

sub menu_item_2_json {

	my ($i) = @_;

	ref $i eq HASH or return ();

	_menu_item ($i);

	return {
		id        => $i -> {id},
		label     => $i -> {label},
		href      => $i -> {href},
		(!$i -> {items} ? () : (items => [map {menu_item_2_json ($_)} @{$i -> {items}}])),
	};

}

################################################################################

sub menu_filtered {

	my ($menu) = @_;

	my @result = ();

	foreach my $i (@$menu) {

		ref $i eq HASH or next;


		if ($i -> {items} && 0 == grep {!$_ -> {off}} @{$i -> {items}}) {
			$i -> {off} = 1;
		}

		next if $i -> {off};

		_menu_item ($i);

		$i -> {items} = menu_filtered ($i -> {items}) if $i -> {items};

		@{$i -> {items}} > 0 or delete $i -> {items};

		push @result, $i;

	}

	\@result;

}


################################################################################

sub draw_page_just_to_reload_menu {

	my ($_SKIN, $page) = @_;

	my $menu = $page -> {menu};

	$menu = menu_filtered ($menu);

	return $_JSON -> encode ([map {menu_item_2_json ($_)} @$menu]);

}

1;