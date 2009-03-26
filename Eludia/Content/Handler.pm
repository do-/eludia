no warnings;

#################################################################################

sub handler {

	my $handler_time = time ();

	$ENV {REMOTE_ADDR} = $ENV {HTTP_X_REAL_IP} if $ENV {HTTP_X_REAL_IP};

	$_PACKAGE ||= __PACKAGE__ . '::';

	my $http_host = $ENV {HTTP_X_FORWARDED_HOST} || $self -> {preconf} -> {http_host};
	
	$ENV {HTTP_HOST} = $http_host if $http_host;

	get_request (@_);	

	my $time = $r -> request_time ();

	$time = __log_profilinig ($handler_time, '<get_request>');

	our $first_time = $time;

	$_REQUEST {__sql_time} = 0;
		
	our %_REQUEST_VERBATIM = %_REQUEST;
	
	our $_QUERY = undef;

	$_REQUEST {__skin} = '';
	
	our $_REQUEST_TO_INHERIT = undef;

	$_REQUEST {__no_navigation} ||= $_REQUEST {select};
	
	if ($_REQUEST {__toolbar_inputs}) {
	
		foreach my $key (split /\,/, $_REQUEST {__toolbar_inputs}) {
		
			$key or next;
			
			exists $_REQUEST {$key} or $_REQUEST {$key} = '';
		
		}
	
	}

	if ($_REQUEST {__form_checkboxes}) {
	
		foreach my $key (split /\,/, $_REQUEST {__form_checkboxes}) {
		
			$key or next;
			
			exists $_REQUEST {$key} or $_REQUEST {$key} += 0;
		
		}
	
	}

	$_REQUEST {type} =~ s/_for_.*//;
	$_REQUEST {__uri} = $r -> uri;
	$_REQUEST {__uri} =~ s{/cgi-bin/.*}{/};
	$_REQUEST {__uri} =~ s{\/\w+\.\w+$}{};
	$_REQUEST {__uri} =~ s{\?.*}{};
	$_REQUEST {__uri} =~ s{^/+}{/};
	$_REQUEST {__uri} =~ s{\&salt\=[\d\.]+}{}gsm;
	
	$_REQUEST {__script_name} = $ENV {SERVER_SOFTWARE} =~ /IIS\/5/ ? $ENV {SCRIPT_NAME} : '';

	$_REQUEST {__windows_ce} = $r -> headers_in -> {'User-Agent'} =~ /Windows CE/ ? 1 : undef;
	
	if ($_REQUEST {fake}) {
    	    $_REQUEST {fake} =~ s/\%(25)*2c/,/ig;
	}

	if ($_REQUEST {action}) {
	
		my $precision = $^V ge v5.8.0 && $Math::FixedPrecision::VERSION ? $conf -> {precision} || 3 : undef;

		foreach my $key (keys %_REQUEST) {

			$key =~ /^_[^_]/ or next;

			$_REQUEST {$key} =~ s{^\s+}{};
			$_REQUEST {$key} =~ s{\s+$}{};
			
			my $encoded = encode_entities ($_REQUEST {$key}, "‚„-‰‹‘-™›\xA0¤¦§©«-®°-±µ-·»");
			
			if ($_REQUEST {$key} ne $encoded) {
				$_REQUEST {$key} = $encoded;
				next;
			}
			
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

	my $request_time = 1000 * (time - $first_time);
		
	require_config ();

	$time = __log_profilinig ($time, '<require_config>');

   	sql_reconnect ();   	
   	
	$time = __log_profilinig ($time, '<sql_reconnect>');

   	require_model ();

	__log_request_profilinig ($request_time);
	
	if ($r -> uri =~ m{/(\w+)\.(css|gif|ico|js|html)$}) {

		my $fn = "$1.$2";

		setup_skin ();

		$r -> internal_redirect ("/i/_skins/$_REQUEST{__skin}/$fn");

		return _ok ();

	}

	if ($_REQUEST {keepalive}) {

		$_REQUEST {virgin} or keep_alive ($_REQUEST {keepalive});

		return out_html ({}, qq{<html><head><META HTTP-EQUIV=Refresh CONTENT="@{[ 60 * $conf -> {session_timeout} - 1 ]}; URL=$_REQUEST{__uri}?keepalive=$_REQUEST{keepalive}"></head></html>});

	}

	if ($_REQUEST {__whois}) {
	
		my $user = sql_select_hash ("SELECT $conf->{systables}->{users}.id, $conf->{systables}->{users}.label, $conf->{systables}->{users}.mail, $conf->{systables}->{roles}.name AS role FROM $conf->{systables}->{sessions} INNER JOIN $conf->{systables}->{users} ON $conf->{systables}->{sessions}.id_user = $conf->{systables}->{users}.id INNER JOIN $conf->{systables}->{roles} ON $conf->{systables}->{users}.id_role = $conf->{systables}->{roles}.id WHERE $conf->{systables}->{sessions}.id = ?", $_REQUEST {__whois});
		
		return out_html ({}, Dumper ({data => $user}));

	}

	$time = __log_profilinig ($time, '<misc>');
	
	our $_USER = get_user ();

	return _ok () if $_REQUEST {__response_sent};

	$time = __log_profilinig ($time, '<got user>');
	
	$_USER -> {id} or $_REQUEST {type} =~ /(logon|_boot)/ or return handle_request_of_type_kickout ();

	require_content DEFAULT;
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

	require_content 'menu';

	our $i18n = i18n ();

	my $menu = call_for_role ('select_menu') || call_for_role ('get_menu');
	
	$_REQUEST {type} or adjust_request_type ($menu);
			
	my $page = {
		menu => $menu,
		type => $_REQUEST {type},
	};

	call_for_role ('get_page');

	$page -> {subset} = $_SUBSET;

	require_both $page -> {type};

	$_REQUEST {__include_js} ||= [];
	push @{$_REQUEST {__include_js}}, @{$conf -> {include_js}} if $conf -> {include_js};

	$_REQUEST {__include_css} ||= [];
	push @{$_REQUEST {__include_css}}, @{$conf -> {include_css}} if $conf -> {include_css};

	$_REQUEST {__last_last_query_string}   ||= $_REQUEST {__last_query_string};
	
	$_REQUEST {__suggest} and return handle_request_of_type_suggest ($page);

	$_REQUEST {action} or return handle_request_of_type_showing ($page);
	
	return handle_request_of_type_action ($page);
	
}

################################################################################

sub handle_error {

	my ($page) = @_;
	
	out_html ({}, draw_page ($page));
	
	return action_finish ();

}

################################################################################

sub handle_request_of_type_kickout {

	foreach (qw(sid salt _salt __last_query_string __last_scrollable_table_row)) {delete $_REQUEST {$_}}

	set_cookie (-name => 'redirect_params', -value => MIME::Base64::encode (Dumper (\%_REQUEST)), -expires => '+1h', -path => '/');

	redirect (
		"/?type=" . ($conf -> {core_skip_boot} || $_REQUEST {__windows_ce} ? 'logon' : '_boot'),
		kind => 'js', 
		target => '_top'
	);

	return handler_finish ();

}

################################################################################

sub handle_request_of_type_action {

	my ($page) = @_;

	my $action = $_REQUEST {action};

	undef $__last_insert_id;

	our %_OLD_REQUEST = %_REQUEST;

	log_action_start ();

	eval { $db -> {AutoCommit} = 0; };

	eval { $_REQUEST {error} = call_for_role ("validate_${action}_$$page{type}"); };
	
	return action_finish () if $_REQUEST {__response_sent};
	
	return handle_error ($page) if $_REQUEST {error};
			
	return action_finish () if $_REQUEST {__peer_server};

	eval {

		delete_fakes () if $action eq 'create';

		call_for_role ("do_${action}_$$page{type}");

		call_for_role ("recalculate_$$page{type}") if $action ne 'create';

	};

	$_REQUEST {error} = $@ if $@;
	
	return handle_error ($page) if $_REQUEST {error};

	$_REQUEST {__response_sent} or redirect (

		$action eq 'delete' ? esc_href () : { action => '', __last_scrollable_table_row => $_REQUEST {__last_scrollable_table_row}},

		{ kind => 'js',	label => $_REQUEST {__redirect_alert} }

	);

	return action_finish ();

}

################################################################################

sub handle_request_of_type_suggest {

	my ($page) = @_;

	setup_skin ();

	call_for_role ("draw_item_of_$$page{type}");
				
	delete $_REQUEST {id};
				
	out_html ({}, draw_suggest_page (&$_SUGGEST_SUB ()));
				
	return handler_finish ();
				
}				

################################################################################

sub handle_request_of_type_showing {

	my ($page) = @_;

	adjust_last_query_string ();
	
	$r -> headers_out -> {'Expires'} = '-1';
			
	out_html ({}, draw_page ($page));

	return handler_finish ();

}

################################################################################

sub handler_finish {

	$r -> pool -> cleanup_register (\&__log_request_finish_profilinig, {
	
		id_request_log		=> $_REQUEST {_id_request_log}, 
		out_html_time		=> $_REQUEST {__out_html_time},
		application_time	=> 1000 * (time - $first_time) - $_REQUEST {__sql_time}, 
		sql_time		=> $_REQUEST {__sql_time},
		is_gzipped		=> $_REQUEST {__is_gzipped},
		
	}) if $preconf -> {core_debug_profiling} > 2;
	
	if ($_REQUEST {__suicide}) {
		$r -> print (' ' x 8192);
		CORE::exit (0);
	}

	__log_profilinig ($first_time, '<TOTAL>');

	return _ok ();

}

################################################################################

sub log_action_start {

	our $__log_id = $_REQUEST {id};
	our $__log_user = $_USER -> {id};
	
	$_REQUEST {error} = substr ($_REQUEST {error}, 0, 255);
	
	$_REQUEST {_id_log} = sql_do_insert ($conf -> {systables} -> {log}, {
		id_user => $_USER -> {id}, 
		type => $_REQUEST {type}, 
		action => $_REQUEST {action}, 
		ip => $ENV {REMOTE_ADDR}, 
		error => $_REQUEST {error}, 
		ip_fw => $ENV {HTTP_X_FORWARDED_FOR},
		fake => 0,
		mac => get_mac (),
	});
		
}

################################################################################

sub log_action_finish {
	
	$_REQUEST {_params} = $_REQUEST {params} = Data::Dumper -> Dump ([\%_OLD_REQUEST], ['_REQUEST']);
	$_REQUEST {_params} =~ s/ {2,}/\t/g;
		
	$_REQUEST {error} = substr ($_REQUEST {error}, 0, 255);
	$_REQUEST {_error}  = $_REQUEST {error};
	$_REQUEST {_id_object} = $__log_id || $_REQUEST {id} || $_OLD_REQUEST {id};
	$_REQUEST {_id_user} = $__log_user || $_USER -> {id};
	
	sql_do_update ($conf -> {systables} -> {log}, ['params', 'error', 'id_object', 'id_user'], {id => $_REQUEST {_id_log}, lobs => ['params']});
	
	delete $_REQUEST {params};
	delete $_REQUEST {_params};
	
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

sub adjust_last_query_string {

	$_REQUEST {sid} && !$_REQUEST {__top} && !$_REQUEST {__only_menu} && $_REQUEST {type} ne '__query' or return;
					
	my $_PREVIOUS_REQUEST = parse_query_string_to_hashref ($r -> headers_in -> {Referer});
	
	$_PREVIOUS_REQUEST -> {action} 
		or $_REQUEST {__last_query_string} != $_PREVIOUS_REQUEST -> {__last_query_string} 
		or $_REQUEST {type}                ne $_PREVIOUS_REQUEST -> {type} 
		or $_REQUEST {__next_query_string} 
		or return;

	my ($method, $url) = split /\s+/, $r -> the_request;
	
	if ($url !~ /\bsid=\d/) {
		
		$url .= '?';
		
		foreach my $k (keys %_REQUEST_VERBATIM) {
		
			next if $_REQUEST_VERBATIM {$k} eq '';
				
			$url .= "$k=";
			$url .= uri_escape ($_REQUEST_VERBATIM {$k});
			$url .= "&";
				
		}
		
		chop $url;
		
	}
	
	$_REQUEST {__last_query_string} = session_access_log_set ($url);
	
	$_REQUEST {__last_last_query_string} ||= $_REQUEST {__last_query_string};
	
}

################################################################################

sub recalculate_logon {

	$_REQUEST {action} =~ /^execute/ or return;

	if ($_USER -> {id}) {

		set_cookie (
			-name    => 'user_login',
			-value   => sql_select_scalar ("SELECT login FROM $conf->{systables}->{users} WHERE id = ?", $_USER -> {id}),
			-expires => '+1M',
			-path    => '/',
		);
		
		if ($preconf -> {core_fix_tz} && $_REQUEST {tz_offset}) {
			sql_do ('UPDATE sessions SET tz_offset = ? WHERE id = ?', $_REQUEST {tz_offset}, $_REQUEST {sid});
		}
		
		session_access_logs_purge ();
		
	}

	if ($_COOKIES {redirect_params}) {
		
		my $VAR1;
		
		my $value = $_COOKIES {redirect_params} -> value;
		
		my $src = MIME::Base64::decode ($value);
	
		eval "\$VAR1 = $src";
		
		$@ and warn "[$src] thaw error: $@\n" and return;

		foreach my $key (keys %$VAR1) { $_REQUEST {$key} = $VAR1 -> {$key} }
		
		set_cookie (
			-name    => 'redirect_params',
			-value   => '',
			-expires => '+1m',
			-path    => '/',
		);
		
	} 

}

1;