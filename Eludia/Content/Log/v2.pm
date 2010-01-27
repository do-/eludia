################################################################################

sub log_action_start {

	our $__log_id     = $_REQUEST {id};
	our $__log_user   = $_USER -> {id};	
	
	setup_json ();
	
	my %r = (%_REQUEST_VERBATIM);
	
	foreach my $name (@{$preconf -> {core_log} -> {suppress} -> {always}}) {delete $r {$name}};
	
	foreach my $name (@{$preconf -> {core_log} -> {suppress} -> {empty}})  {delete $r {$name} if $r {$name} eq ''};
	
	foreach my $name (grep {$_} split /\,/, delete $r {__form_checkboxes})  {$r {$name} ||= ''};
	
	my $params = $_JSON -> encode (\%r);

	chop ($params);
	
	my $r = {
	
		fake    => 0,
		
		id_user => $__log_user,

		action  => $_REQUEST {action},
		
		params  => substr ($params, 1),
		
		ip      => $ENV      {REMOTE_ADDR},
		
		ip_fw   => $ENV      {HTTP_X_FORWARDED_FOR},
		
	};

	$r -> {mac} = get_mac () if $conf -> {core_log} -> {log_mac};

	$_REQUEST {_id_log} = sql_do_insert ($conf -> {systables} -> {log}, $r);

}

################################################################################

sub log_action_finish {

	$__log_id   ||= ($_REQUEST {id} || $_OLD_REQUEST {id} || $_REQUEST_VERBATIM {id});
	
	$__log_user ||=  $_USER -> {id};

	my $fields = 'href = ?, id_user = ?';
	
	my $href = $_REQUEST_VERBATIM {type} || $_REQUEST {type};
	
	$href .= "&id=$__log_id" if $__log_id;

	my @values = ($href, $__log_user);
	
	if ($_REQUEST {error}) {
	
		$fields .= ', error = ?';
		
		push @values, $_REQUEST {error};
	
	}
	else { ### not empty_clob (if any), but exactly NULL

		$fields .= ', error = NULL';

	}

	sql_do ("UPDATE $conf->{systables}->{log} SET $fields WHERE id = ?", @values, $_REQUEST {_id_log});

}

1;