
################################################################################

sub _fix_menu {

	my ($menu) = @_;

	my @result = ();

	foreach my $i (@$menu) {

		ref $i eq HASH or next;


		if ($i -> {items} && 0 == grep {!$_ -> {off}} @{$i -> {items}}) {
			$i -> {off} = 1;
		}

		next if $i -> {off};

		$_SKIN -> __adjust_menu_item ($i);

		$i -> {items} = _fix_menu ($i -> {items}) if $i -> {items};

		@{$i -> {items}} > 0 or delete $i -> {items};

		push @result, {
			id        => $i -> {id},
			label     => $i -> {label},
			href      => $i -> {href},
			side      => $i -> {side},
			(!$i -> {items} ? () : (items => $i -> {items})),
		};

	}

	\@result;

}
################################################################################

sub get_data_menu {

	my $menu = setup_menu ();

	return draw_menu (_fix_menu ($menu));

}



################################################################################

sub do_serialize_menu {

	my $content = get_user_subset_menu ();

	$content -> {md5} = Digest::MD5::md5_hex (Dumper ($content));

	out_html ({}, $_JSON -> encode ($content));

}

1;