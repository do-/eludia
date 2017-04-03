no warnings;

################################################################################

sub draw_hash {

	my ($h) = @_;
	
	$_REQUEST {__content_type} = 'application/json';

	$_JSON -> encode ($h);

}

################################################################################

sub draw_page {

	my ($page) = @_;
		
	return draw_hash ({ 
	
		content => $page -> {content},

	});

}

################################################################################

sub draw_error_page {

	my $h = {};
	
	if ($_REQUEST {error} =~ /^\#(.*?)\#\:/) {
	
		$h -> {field}   = $1;
		$h -> {message} = $';
		$h -> {message} =~ s{ at .*}{}gsm;
		
	}
	else {
		$h -> {message} = $_REQUEST {error};
	}

	return draw_hash ($h);

}

#################################################################################

sub handler {
          
	our @_PROFILING_STACK = ();

	__profile_in ('handler.request'); 
	
	get_request (@_);

	if ($ENV {REQUEST_METHOD} ne 'POST') {
		$r -> status (405);
		send_http_header ();
		return $r -> status ();
	}
	
	if ($r -> header_in ('Content-Type') ne 'application/json') {
		$r -> status (400);
		send_http_header ();
		$r -> print ('Wrong Content-Type');
		return $r -> status ();
	}
	
	Encode::_utf8_on ($_) foreach (values %_REQUEST);

	setup_json ();

	if (my $postdata = delete $_REQUEST {POSTDATA}) {
	
		eval {%_REQUEST = (%_REQUEST, %{$_JSON -> decode ($postdata)})};
		
		if ($@) {
			$r -> status (400);
			send_http_header ();
			$r -> print ('Wrong JSON: ' . $@);
			return $r -> status ();
		}
	
	}

	my $code;
	
	eval {
	
		return _ok () if page_is_not_needed (@_);

		__profile_in ('handler.setup_page'); 

		my $page = setup_page ();
		
		__profile_out ('handler.setup_page'); 

		__profile_in ("handler.$page->{request_type}"); 

		my $code = &{"handle_request_of_type_$page->{request_type}"} ($page);
		
		__profile_out ("handler.$page->{request_type}");

		return $code;

	};

	if ($@) {
		
		$r -> status (500);
		
		send_http_header ();
		
		my $time = time;
		
		my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ($time);
		
		my $h = {
			id => Digest::MD5::md5_hex ($$ . $@ . time () . rand ()),
			dt => sprintf ('%04d-%02d-%02d %02d:%02d:%02d.%03d', $year + 1900, $mon + 1, $mday, $hour, $min, $sec, 1000 * ($time - int $time)),
		};
		
		warn "[$h->{dt} $$]\t$h->{id}\t$@\n";
		
		$h -> {dt} =~ y{ }{T};
		
		$r -> print ($_JSON -> encode ($h));
		
		return 500;
		
	}

	__profile_out ('handler.request' => {label => "type='$_REQUEST_VERBATIM{type}' id='$_REQUEST_VERBATIM{id}' action='$_REQUEST_VERBATIM{action}' id_user='$_USER->{id}'"}); warn "\n";

	return $code;

}

#################################################################################

sub page_is_not_needed {

	__profile_in ('handler.prelude'); 

	our $i18n = i18n ();

	require_config           (  );

	sql_reconnect            (  );

	require_model            (  );

	setup_request_params     (@_);
	
	__profile_in ('handler.setup_user'); 

	setup_user ();

	__profile_out ('handler.setup_user', {label => "id_user=$_USER->{id}, ip=$_USER->{ip}, ip_fw=$_USER->{ip_fw}, sid=$_REQUEST{sid}"});

	__profile_out ('handler.prelude'); 

	return $_USER ? 0 : 1;

}

################################################################################

sub setup_user {
	
	our $_USER = get_user ();
	
	return 1 if $_USER -> {id} or $_REQUEST {type} eq 'sessions';
	
	handle_request_of_type_kickout ();
	
	return 0;	

}

################################################################################

sub setup_request_params {

	__profile_in ('handler.setup_request_params'); 

	$ENV {REMOTE_ADDR} = $ENV {HTTP_X_REAL_IP} if $ENV {HTTP_X_REAL_IP};

	$ENV {DOCUMENT_ROOT} ||= $preconf -> {_} -> {docroot};

	$_PACKAGE ||= __PACKAGE__ . '::';

	my $http_host = $ENV {HTTP_X_FORWARDED_HOST} || $self -> {preconf} -> {http_host};
	
	$ENV {HTTP_HOST} = $http_host if $http_host;
	
	our %_REQUEST_VERBATIM = %_REQUEST;
	
	our %_COOKIE = (map {$_ => $_COOKIES {$_} -> value || ''} keys %_COOKIES);
	
	$_REQUEST {sid} = sql_select_scalar ("SELECT id FROM $conf->{systables}->{sessions} WHERE client_cookie = ?", $_COOKIE {sid});
			
	our $_QUERY = undef;
			
	our $_SO_VARIABLES = {};

	$_REQUEST {type} =~ s/_for_.*//;
	
	setup_request_params_for_action () if $_REQUEST {action};
	
	__profile_out ('handler.setup_request_params', {label => "type='$_REQUEST_VERBATIM{type}' id='$_REQUEST_VERBATIM{id}' action='$_REQUEST_VERBATIM{action}'"}); 
	
}

################################################################################

sub setup_request_params_for_action {

	my $precision = $^V ge v5.8.0 && $Math::FixedPrecision::VERSION ? $conf -> {precision} || 3 : undef;

	if ($_REQUEST {__form_checkboxes}) {
	
		foreach my $key (split /\,/, $_REQUEST {__form_checkboxes}) {
		
			$key or next;
			
			exists $_REQUEST {$key} or $_REQUEST {$key} += 0;
		
		}
	
	}
	
	my @names = keys %_REQUEST;

	my @get_ids = ();

	foreach (@names) {
	
		/^__get_ids_/ or next;
	
		push @get_ids, '_' . $';
	
	}
	
	foreach my $key (@get_ids) {
	
		next if $key =~ /\[/;
	
		my @ids = ();
		
		foreach my $name (@names) {
		
			$name =~ /^${key}_/ or next;
			
			push @ids, $';
		
		}
		
		$_REQUEST {$key} = \@ids;
	
		$_REQUEST {$key . ',-1'} = join ',', (@ids, -1);

	}

	foreach my $key (@names) {

		$key =~ /^_[^_]/ or next;

		$_REQUEST {$key} =~ s{^\s+}{};
		$_REQUEST {$key} =~ s{\s+$}{};
				
		next if $key =~ /^_dt/;
		next if $key =~ /^_label/;
		next if $key =~ /_ids$/;
		
		$_REQUEST {$key} =~ /^\-?[\d ]*\d([\,\.]\d+)?$/ or next;

		$_REQUEST {$key} =~ s{ }{}g;
		$_REQUEST {$key} =~ y{,}{.};
		
		defined $precision or next;

		$_REQUEST {$field} = new Math::FixedPrecision ($_REQUEST {$field}, 0 + $precision);

	}

}

################################################################################

sub setup_page {

	my $page = {
		subset => setup_subset (),
		menu   => setup_menu (),
	};
	
	$page -> {type} = $_REQUEST {type};

	if ($ENV {FCGI_ROLE}) {
		my $process = $0;
		$process =~ s#(.*/)?([\w\.]+).*#$2#;
		$process .= " $ENV{SERVER_NAME}: type=$_REQUEST{type}, id=$_REQUEST{id}, action=$_REQUEST{action}";
		$0 = $process;
	}

	call_for_role ('get_page', $page);

	require_content $page -> {type};
			
	$page -> {request_type} = 

		$_REQUEST {action}    ? 'action'  :

					'showing' ;		

	return $page;

}

################################################################################

sub setup_subset {

	require_content 'subset';

	our $_SUBSET = call_for_role ('select_subset');
	
	if ($_SUBSET && $_SUBSET -> {items}) {

		$_SUBSET -> {items} = [ grep {!$_ -> {off}} @{$_SUBSET -> {items}} ];

		$_REQUEST {__subset} ||= $_USER -> {subset};
		$_SUBSET -> {name}   ||= $_REQUEST {__subset};

		my $n = 0;
		my $found = 0;

		foreach my $item (@{$_SUBSET -> {items}}) {
			$n ++;
			$found = 1 if $item -> {name} eq $_SUBSET -> {name};
		}

		$found or delete $_SUBSET -> {name};

		$_SUBSET -> {name} ||= $_SUBSET -> {items} -> [0] -> {name} if $n > 0;

		$_SUBSET -> {name} eq $_USER -> {subset} or sql_do ("UPDATE $conf->{systables}->{users} SET subset = ? WHERE id = ?", $_SUBSET -> {name}, $_USER -> {id});

	}
	
	return $_SUBSET;	

}

################################################################################

sub setup_menu {

	require_content 'menu';

	$i18n = i18n ();

	my $menu = call_for_role ('select_menu') || call_for_role ('get_menu');
	
	ref $menu or $menu = [];
	
	$_REQUEST {type} or adjust_request_type ($menu);
	
	return $menu;

}

################################################################################

sub handle_error {

	my ($page) = @_;
	
	out_html ({}, draw_error_page ($page));
	
	return action_finish ();

}

################################################################################

sub handle_request_of_type_kickout {
	$r -> status (401);
	send_http_header ();
}

################################################################################

sub handle_request_of_type_action {

	require_content DEFAULT;

	my ($page) = @_;

	my $action = $_REQUEST {action};

	undef $__last_insert_id;

	log_action_start ();

	eval { $db -> {AutoCommit} = 0; };
	
	my $result;

	eval {

		$result = call_for_role ("do_${action}_$$page{type}");

		call_for_role ("recalculate_$$page{type}");

	};
	
	if ($@) {
		
		$_REQUEST {error} = $@;

		return handle_error ($page);
	
	}

	$_REQUEST {__response_sent} or out_html ({}, draw_hash ({data => $result}));

	return action_finish ();

}

################################################################################

sub setup_page_content {

	my ($page) = @_;
		
	eval { $page -> {content} = call_for_role (($_REQUEST {id} ? 'get_item_of_' : 'select_') . $page -> {type})};

	$@ and return $_REQUEST {error} = $@;
	
	$_REQUEST {__page_content} = $page -> {content};

}

################################################################################

sub handle_request_of_type_showing {

	my ($page) = @_;
		
	setup_page_content ($page) unless $_REQUEST {__only_menu};
	
	return handler_finish () if $_REQUEST {__response_sent} && !$_REQUEST {error};

	out_html ({}, draw_page ($page));

	return handler_finish ();

}

################################################################################

sub handler_finish {

	sql_disconnect () if $ENV {SCRIPT_NAME} eq '/__try__and__disconnect';
	
	__profile_in ('core.memory');
	
	if (my $memory_usage = memory_usage ()) {
	
		if (exists $preconf -> {core_memory_limit} && $memory_usage >> 20 > $preconf -> {core_memory_limit}) {

			__profile_out ('core.memory', {label => sprintf ("Memory limit of %s MiB exceeded: have %s MiB. This was the suicide note.", $preconf -> {core_memory_limit}, $memory_usage >> 20)});

			$_REQUEST {__suicide} = 1;

		}		
		else {

			$preconf -> {_} -> {memory} -> {last} ||= $preconf -> {_} -> {memory} -> {first};

			__profile_out ('core.memory', {label => sprintf (

				"%s MiB (%s B: first + %s B; last + %s B)", 

				$memory_usage >> 20,

				$memory_usage,

				$memory_usage - $preconf -> {_} -> {memory} -> {first},

				$memory_usage - $preconf -> {_} -> {memory} -> {last},

			)});

			$preconf -> {_} -> {memory} -> {last} = $memory_usage;
		
		}

	}
	else {
	
		__profile_out ('core.memory', {label => 'disabled'});
		
	}
	
	return _ok ();

}

################################################################################

sub action_finish {

	unless ($db -> {AutoCommit}) {

		eval {

			if ($_REQUEST {error}) {
				$db -> rollback
			} 
			else {
				$db -> commit
			} 

			$db -> {AutoCommit} = 1;

		};

	}

	log_action_finish ();
	
	return handler_finish ();

}

################################################################################

sub adjust_request_type {

	my ($items) = @_;
	
	ref $items eq ARRAY or return 0;
	
	foreach my $i (@$items) {
	
		next if $i -> {off};
	
		if ($i -> {href}) {
		
			my $href = $i -> {href};
			
			ref $href or $href = parse_query_string_to_hashref ($href);
			
			while (my ($k, $v) = each %$href) { $_REQUEST {$k} = $v }
										
			return 1;
		
		}
		elsif (!$i -> {no_page} && $i -> {name}) {
		
			$_REQUEST {type} = $i -> {name};
			
			return 1;
		
		}
	
	}
	
	foreach my $i (@$items) {
	
		next if $i -> {off};

		adjust_request_type ($i -> {items}) and return 1;

	}
	
	return 0;

}

################################################################################

sub parse_query_string_to_hashref {
	
	my $h = {};
	
	$_[0] =~ /\?/ or return $h;
		
	foreach (split /\&/, $') {

		my ($k, $v) = split /\=/;

		$h -> {$k} = $v;

	}
	
	return $h;

}

################################################################################

sub recalculate_sessions {

	$_REQUEST {action} =~ /^execute/ or return;
	
	$_USER = get_user ();
	
	$_USER -> {id} or return;
	
	my $h = {
		ip    => $ENV {REMOTE_ADDR},
		ip_fw => $ENV {HTTP_X_FORWARDED_FOR},
	};
	
	$h -> {tz_offset} = $_REQUEST {tz_offset} if $preconf -> {core_fix_tz} && $_REQUEST {tz_offset};
	
	if ($conf -> {core_delegation} && !$_USER -> {id__real}) {
		$_USER -> {id__real} or $h -> {id_user_real} = $_USER -> {id};
	}
	
	sql_select_id ($conf -> {systables} -> {sessions} => $h, ['id']);
	
}

################################################################################

sub out_html {

	my ($options, $html) = @_;

	$html and !$_REQUEST {__response_sent} or return;

	__profile_in ('core.out_html'); 

	$html = Encode::encode ('utf-8', $html);

	return print $html if $_REQUEST {__response_started};

	$r -> content_type ($_REQUEST {__content_type} ||= 'text/html; charset=utf-8');
	
	$r -> headers_out -> {'Content-Length'} = my $length = length $html;
		
	send_http_header ();

	$r -> header_only && !MP2 or print $html;
	
	$_REQUEST {__response_sent} = 1;

	__profile_out ('core.out_html' => {label => "$length bytes"});

}

################################################################################

sub out_json ($) {

	out_html ({}, $_JSON -> encode ($_[0]));

}

1;