################################################################################

sub log_action_start {

	our $__log_id     = $_REQUEST {id};
	our $__log_user   = $_USER -> {id};

	$_REQUEST {error} = substr ($_REQUEST {error}, 0, 255);

	my $r = {
		fake    => 0,
		id_user => $_USER -> {id},
		type    => $_REQUEST {type},
		action  => $_REQUEST {action},
		error   => $_REQUEST {error},
		ip      => $ENV      {REMOTE_ADDR},
		ip_fw   => $ENV      {HTTP_X_FORWARDED_FOR},
	};

	$r -> {mac} = get_mac () if $preconf -> {_} -> {core_log} -> {log_mac};

	$_REQUEST {_id_log} = sql_do_insert ($conf -> {systables} -> {log}, $r);

}

################################################################################

sub log_action_finish {

	$_REQUEST {_params}    =  $_REQUEST {params} = Data::Dumper -> Dump ([\%_REQUEST_VERBATIM], ['_REQUEST']);
	$_REQUEST {_params}    =~ s/ {2,}/\t/g;

	my @fields = qw (params error id_object id_user);

	$_REQUEST {error}      =  substr ($_REQUEST {error}, 0, 255);
	$_REQUEST {_error}     =  $_REQUEST {error};
	$_REQUEST {_id_object} =  $__log_id || $_REQUEST {id} || $_OLD_REQUEST {id} || $_REQUEST_VERBATIM {id} || undef;
	$_REQUEST {_id_user}   =  $__log_user || $_USER -> {id};

	if ($conf -> {core_delegation}) {

		push @fields, 'id_user_real';

		$_REQUEST {_id_user_real} = $_USER -> {id__real};

	}

	sql_do_update ($conf -> {systables} -> {log}, \@fields, {id => $_REQUEST {_id_log}});

	delete $_REQUEST {params};
	delete $_REQUEST {_params};

}

1;