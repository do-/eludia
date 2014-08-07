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
	} else {
		$i -> {href} ||= "/?type=$i->{name}";
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

################################################################################

sub vert_menu_2_ken {

	my ($types) = @_;

	[map {

		ref $_ ne HASH ? () : {
			text  => $_ -> {label},
			url   => $_ -> {href},
			target => $_ -> {target},
			(!$_ -> {icon}  ? () : (imageUrl => "/i/images/icons/$_->{icon}.png")),
			(!$_ -> {items} ? () : (items => vert_menu_2_ken ($_ -> {items}))),
			(!$_ -> {clipboard_text} ? () : (clipboard_text => $_ -> {clipboard_text})),
		}

	} @$types];

}

################################################################################

sub draw_vert_menu {

	my ($_SKIN, $name, $types, $level, $is_main) = @_;

	vert_menu_2_ken ($types);

}

################################################################################

sub draw_tree {

	my ($_SKIN, $node_callback, $list, $options) = @_;

	foreach my $i (@$list) {

		foreach my $key (keys %{$i -> {__node}}) {
			$i -> {$key} = $i -> {__node} -> {$key};
			$i -> {menu} = $i -> {__menu};
		}

		$i -> {href}   = $options -> {url_base} . $i -> {href};

		delete $i -> {__node};
		delete $i -> {level};
	};
}


################################################################################

sub draw_node {

	my ($_SKIN, $options, $i) = @_;

	my $node = {
		id      => $options -> {id},
		text    => $options -> {label},
		parent   => $i -> {parent},
		target   => $i -> {target},
		href     => ($options -> {href_tail} ? '' : $ENV {SCRIPT_URI}) . $options -> {href},
		imageUrl => $options -> {icon}? _icon_path ($options -> {icon}) : undef,
		clipboard_text => $i -> {clipboard_text},
	};

	return $node;
}

################################################################################

sub _icon_path {

	if (-r $r -> document_root . "/i/images/icons/$_[0].png") {
		return "$_REQUEST{__static_site}/i/images/icons/$_[0].png";
	}

	-r $r -> document_root . "/i/_skins/Mint/i_$_[0].png" ?
		"$_REQUEST{__static_url}/i_$_[0].png?$_REQUEST{__static_salt}" :
		"$_REQUEST{__static_site}/i/buttons/$_[0].png";
}

################################################################################

sub __adjust_vert_menu_item {}

1;