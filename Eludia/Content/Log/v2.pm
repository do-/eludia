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
	
	$params = substr ($params, 1);

	my $params_size = (
	
		$preconf -> {_} -> {core_log} -> {params_size} ||= (
	
			($model_update -> get_columns ($conf -> {systables} -> {log})) -> {params} -> {COLUMN_SIZE} 
		
			|| -1
			
		)
			
	);
	
	$params_size = 1000 if $params_size == 4000;
			
	if ($params_size > -1) {
	
		while (length $params > $params_size) {

			my $portion = substr $params, length ($params) - $params_size;

			my $id = sql_do_insert ($conf -> {systables} -> {log}, {fake => 0, params => $portion});
			
			$params_size > 1 + length ($id) or die "Too small log.params field\n";

			$params = (substr $params, 0, length ($params) - $params_size) . "�$id";

		}

	}	
	
	my $r = {
	
		fake    => 0,
		
		id_user => $__log_user,

		action  => $_REQUEST {action},
		
		params  => $params,
		
		ip      => $ENV      {REMOTE_ADDR},
		
		ip_fw   => $ENV      {HTTP_X_FORWARDED_FOR},
		
	};

	$r -> {mac} = get_mac () if $preconf -> {_} -> {core_log} -> {log_mac};

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

	if ($conf -> {core_delegation}) {
	
		$fields .= ', id_user_real = ?';
	
		push @values, $_USER -> {id__real};
	
	}

	sql_do ("UPDATE $conf->{systables}->{log} SET $fields WHERE id = ?", @values, $_REQUEST {_id_log});

}

1;