package Eludia::Presentation::Skins::JSONDumper;

################################################################################

sub options { return {no_presentation => 1}}

################################################################################

sub no_presentation { 1 }

################################################################################

sub draw_hash {

	my ($_SKIN, $h) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=utf-8';

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
	}
	else {
		$i -> {href} ||= "/?type=$i->{name}";
		$i -> {href}  .= "&sid=$_REQUEST{sid}";
	}

	$i -> {id} ||= $i -> {href};
	
	$i -> {id} =~ s{[\&\?]?sid\=\d+}{};
	
	$i -> {icon} ||= 'page_white';

}

################################################################################

sub menu_item_2_json {

	my ($i) = @_;
		
	ref $i eq HASH or return ();	

	_menu_item ($i);
	
	{
		id        => $i -> {id},
		rel       => $i -> {href},
		favorites => \$i -> {is_favorite},
		popular   => \$i -> {is_popular},
		text      => $i -> {label},
		(!$i -> {items} ? () : (items => [map {menu_item_2_json ($_)} @{$i -> {items}}])),
	};

}

################################################################################

sub menu_add_fav {

	my ($menu, $fav, $key) = @_;
	
	foreach my $i (@$menu) {
	
		_menu_item ($i);
	
		$i -> {$key} = 0 + $fav -> {$i -> {id}};
		
		menu_add_fav ($i -> {items}, $fav, $key) if $i -> {items};

	}

}

################################################################################

sub menu_filtered {

	my ($menu) = @_;
	
	my @result = ();
	
	foreach my $i (@$menu) {
	
		ref $i eq HASH or next;	

		next if $i -> {off};
			
		$i -> {items} = menu_filtered ($i -> {items}) if $i -> {items};
		
		@{$i -> {items}} > 0 or delete $i -> {items};
		
		!$_REQUEST {__only_favorites} or $i -> {is_favorite} or $i -> {items} or next;
		!$_REQUEST {__only_popular}   or $i -> {is_popular}  or $i -> {items} or next;

		push @result, $i;

	}
	
	\@result;

}

################################################################################

sub draw_page_just_to_reload_menu {

	my ($_SKIN, $page) = @_;
	
	my $menu = $page -> {menu};

	my %fav = ();
	
	&{$_PACKAGE . 'sql_select_loop'} (
	
		'SELECT name FROM __menu WHERE fake = 0 AND is_favorite = 1 AND id_user = ?', 

		sub {$fav {${$_PACKAGE . 'i'} -> {name}} = 1}, 

		$_USER -> {id}

	);
	
	menu_add_fav ($menu, \%fav, 'is_favorite');

	my %pop = ();
	my $dt = &{$_PACKAGE . 'dt_iso'} (Date::Calc::Add_Delta_YM (Date::Calc::Today (), 0, -3));
	
	&{$_PACKAGE . 'sql_select_loop'} (q {
	
			SELECT
				name
			FROM
				__menu_clicks
			WHERE
				id_user = ?
				AND dt >= ?
				AND name <> ?
			GROUP BY
				name
			ORDER BY
				SUM(cnt) DESC
				
		}, 
		
		sub {
			return if %pop >= 15;
			$pop {${$_PACKAGE . 'i'} -> {name}} = 1;
		}, 
		
		$_USER -> {id},
		
		$dt,
		
		'undefined',

	);
	
	menu_add_fav ($menu, \%pop, 'is_popular');
	
	$menu = menu_filtered ($menu);

	$_JSON -> encode ([map {menu_item_2_json ($_)} @$menu]);
				
}

################################################################################

sub draw_node {

	my ($_SKIN, $options, $i) = @_;

	my $node = {
		id      => $options -> {id},
		text    => $options -> {label}, 
		href    => ($options -> {href_tail} ? '' : $ENV {SCRIPT_URI}) . $options -> {href},
#		title   => $options -> {title} || $options -> {label},
	};

#	map {$node -> {$_} = $options -> {$_} if $options -> {$_}} qw (target icon iconOpen is_checkbox is_radio);

#	if ($options -> {title} && $options -> {title} ne $options -> {label}) {
#		$node -> {title} = $options -> {title};
#	}
	
	$i -> {hasChildren} = $i -> {cnt_children} ? \1 : \0;
	
	$node -> {context_menu} = $i . '' if $i -> {__menu};

	return $node;

}

################################################################################

sub draw_tree {

	my ($_SKIN, $node_callback, $list, $options) = @_;
		
	my %p2n = ();
	my %i2n = ();
	
	foreach my $i (@$list) {
	
		my $n = $i -> {__node};
		
		my $nn = {
			id          => $i -> {id},
			text        => $n -> {text},
			href        => $n -> {href},
			hasChildren => $n -> {hasChildren},
		};
	
		push @{$p2n {0 + $i -> {parent}} ||= []}, $nn;
	
		$i2n {$i -> {id}} = $nn;
	
	}

	foreach my $nn (values %i2n) {

		my $items = $p2n {$nn -> {id}} or next;

		$nn -> {items} = $items;

	}

	my $data = $_JSON -> encode ($p2n {$_REQUEST {__parent} || 0} ||= []);

}

1;