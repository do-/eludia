no warnings;

#################################################################################

sub handler {

	our @_PROFILING_STACK = ();

	__profile_in ('handler.request');

	my $code;

	eval {

		my $page_is_not_needed = eval { page_is_not_needed (@_) };

		return _ok () if $page_is_not_needed;

		$code = $@ ? 500 : eval {

			__profile_in ('handler.setup_page');

			my $page = setup_page ();

			__profile_out ('handler.setup_page');

			__profile_in ("handler.$page->{request_type}");

			my $code = &{"handle_request_of_type_$page->{request_type}"} ($page);

			__profile_out ("handler.$page->{request_type}");

			return $code;

		};

		if ($@) {

			warn "$@\n";

			out_script (q {

				var d = window.top.document;

				d.write ('<pre>' + data + '</pre>');

				d.close ();

			}, $@);

			return _ok ();

		}

	};

	__profile_out ('handler.request' => {label => "type='$_REQUEST_VERBATIM{type}' id='$_REQUEST_VERBATIM{id}' action='$_REQUEST_VERBATIM{action}' id_user='$_USER->{id}'"}); warn "\n";

	if ($_REQUEST {__suicide}) {
		$r -> print (' ' x 8192);
		CORE::exit (0);
	}

	return $code;

}

#################################################################################

sub page_is_not_needed {

	__profile_in ('handler.prelude');

	our $i18n = i18n ();

	setup_request_params     (@_);

	if ($ENV {REQUEST_METHOD} eq 'OPTIONS') {

		$r -> headers_out -> {'Allow'} = 'PROPFIND, DELETE, MKCOL, PUT, MOVE, COPY, PROPPATCH, LOCK, UNLOCK, OPTIONS, GET, HEAD, POST';
		$r -> headers_out -> {'DAV'} = '1,2';
		$r -> headers_out -> {'MS-Author-Via'} = 'DAV';
		$r -> headers_out -> {'Content-Length'} = '0';
		send_http_header ();
		$_REQUEST {__response_sent} = 1;

		return 1;
	}

	require_config           (  );

	sql_reconnect            (  );

	require_model            (  );

	__profile_in ('handler.setup_user');

	my $u = setup_user ();

	__profile_out ('handler.setup_user', {label => "id_user=$_USER->{id}, ip=$_USER->{ip}, ip_fw=$_USER->{ip_fw}, sid=$_REQUEST{sid}"});

	__profile_out ('handler.prelude');

	return $u ? 0 : 1;

}

################################################################################

sub setup_user {

	if ($r -> uri =~ m{/(\w+)\.(css|gif|ico|js|html)$}) {

		my $fn = "$1.$2";

		setup_skin ();

		$r -> internal_redirect ("/i/_skins/$_REQUEST{__skin}/$fn");

		return 0;

	}

	elsif ($_REQUEST {keepalive}) {

		if (sql_select_scalar ("SELECT id FROM $conf->{systables}->{sessions} WHERE id = ?", $_REQUEST {keepalive})) {

			$_REQUEST {virgin} or keep_alive ($_REQUEST {keepalive});

			out_html ({}, qq{<html><head><META HTTP-EQUIV=Refresh CONTENT="@{[ 60 * $conf -> {session_timeout} - 1 ]}; URL=$_REQUEST{__uri}?keepalive=$_REQUEST{keepalive}"></head></html>});

		}
		else {

			out_html ({}, qq{<html><body onLoad="open('/', '_top')"></body></html>});

		}

		return 0;

	}

	elsif ($_REQUEST {__whois}) {

		my $user = sql_select_hash ("SELECT $conf->{systables}->{users}.id, $conf->{systables}->{users}.label, $conf->{systables}->{users}.mail, $conf->{systables}->{roles}.name AS role FROM $conf->{systables}->{sessions} INNER JOIN $conf->{systables}->{users} ON $conf->{systables}->{sessions}.id_user = $conf->{systables}->{users}.id LEFT JOIN $conf->{systables}->{roles} ON $conf->{systables}->{users}.id_role = $conf->{systables}->{roles}.id WHERE $conf->{systables}->{sessions}.id = ?", $_REQUEST {__whois});

		out_html ({}, Dumper ({data => $user}));

		return 0;

	}

	our $_USER = get_user ();

	return 1 if $_USER -> {id} or $_REQUEST {type} =~ /(logon|_boot)/;

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

	get_request (@_);
	our %_REQUEST_VERBATIM = %_REQUEST;

	our %_COOKIE = (map {$_ => $_COOKIES {$_} -> value || ''} keys %_COOKIES);

	if ($r -> {headers_in} -> {'User-Agent'} =~ /^Microsoft/) {
		$_REQUEST {type} = $_REQUEST_VERBATIM {type} = 'webdav';
		$_REQUEST {method} = $ENV {REQUEST_METHOD};

		$_REQUEST {query} ||= $ENV {'REQUEST_URI'};
		$_REQUEST {query} =~ s/\/webdav\///;
		$_REQUEST {query} =~ s/^([a-z0-9]+)_(\d+)_//;
		$_COOKIE {client_cookie} = $1;
		$_REQUEST {sid} ||= $2;
	}

	set_cookie_for_root (
		client_cookie => $_COOKIE {client_cookie} || Digest::MD5::md5_hex (rand ())
		, $preconf -> {core_auth_join_session}? 'session' : ''
	);

	my $encode_utf = $ENV {HTTP_CONTENT_TYPE} =~ /charset=UTF-8/i && $i18n -> {_charset} eq 'windows-1251';
	foreach my $k (keys %_REQUEST) {

		my $k_ = $k;
		if ($k =~ s/</&lt;/g || $k =~ s/>/&gt;/g) {
			$_REQUEST {$k} = delete $_REQUEST {$k_};
		}

		$_REQUEST {$k} =~ s/</&lt;/g; $_REQUEST {$k} =~ s/>/&gt;/g;

		if ($encode_utf) {
			$_REQUEST {$k} = encode ("cp1251", decode ("utf-8", $_REQUEST {$k}));
		}

	}

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

	our $_SO_VARIABLES = {};

	$_REQUEST {type} =~ s/_for_.*//;
	$_REQUEST {__uri} = $r -> uri;
	$_REQUEST {__uri} =~ s{/cgi-bin/.*}{/};
	$_REQUEST {__uri} =~ s{/\w+\.\w+$}{};
	$_REQUEST {__uri} =~ s{\?.*}{};
	$_REQUEST {__uri} =~ s{^/+}{/};
	$_REQUEST {__uri} =~ s{\&salt\=[\d\.]+}{}gsm;
	$_REQUEST {__uri} =~ s{(\.\w+)/$}{$1};

	$_REQUEST {__script_name} = $ENV {SERVER_SOFTWARE} =~ /IIS\/5/ ? $ENV {SCRIPT_NAME} : '';

	$_REQUEST {__windows_ce} = $r -> headers_in -> {'User-Agent'} =~ /Windows CE/ ? 1 : undef;

	if ($_REQUEST {fake}) {
		$_REQUEST {fake} =~ s/\%(25)*2c/,/ig;
		$_REQUEST {fake} = join ',', map {0 + $_} split /,/, $_REQUEST {fake};
		$_REQUEST {q}    =~ s/(^\s+)|(\s+$)//g;
	}

	$_REQUEST {__last_last_query_string}   ||= $_REQUEST {__last_query_string};

	$_REQUEST {lpt} ||= $_REQUEST {xls};

	$_REQUEST {__read_only} = 1 if $_REQUEST {lpt};

	$_REQUEST {__read_only} = $_REQUEST {__pack} = $_REQUEST {__no_navigation} = 1 if $_REQUEST {__popup};

	$_REQUEST {__page_title} ||= $conf -> {page_title};

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

################################################################################

sub setup_page {

	my $page = $_REQUEST {type} ? {
			subset => [],
			menu   => [],
		} :	{
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

	require_both $page -> {type};

	$page -> {request_type} =

		$_REQUEST {__suggest} ? 'suggest' :

		$_REQUEST {action}    ? 'action'  :

		$r -> headers_in -> {'X-Requested-With'} eq 'XMLHttpRequest' ? 'data' :

					'showing' ;

	if ($page -> {request_type} eq 'showing' && !@{$page -> {menu}}) {

		$page -> {subset} = setup_subset ();
		$page -> {menu}   = setup_menu ();

	} else {

		require_content 'subset';
		require_content 'menu';

	}

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

	if ($_REQUEST {type} eq 'webdav') {

		$r -> status (401); # unauthorized

		send_http_header ();

		$_REQUEST {__response_sent} = 1;

		return handler_finish ();
	}

	foreach (qw(sid salt _salt __last_query_string __last_scrollable_table_row)) {delete $_REQUEST {$_}}

	unless ($r -> headers_in -> {'X-Requested-With'} eq 'XMLHttpRequest') {
		setup_json ();
		my %_R = map {$_ => $_REQUEST {$_}} grep {!ref $_REQUEST {$_}} keys %_REQUEST;
		set_cookie (
			-name => 'redirect_params',
			-value => $i18n -> {_charset} eq 'windows-1251' ?
				encode ('utf-8', decode ('windows-1251', $_JSON -> encode (\%_R))) :
				$_JSON -> encode (\%_R),
			-path => '/'
		);
	}

	redirect (
		"/?type=" . ($conf -> {core_skip_boot} || $_REQUEST {__windows_ce} ? 'logon' : '_boot'),
		{
			kind => 'js',
			target => '_top'
		},
	);

	return handler_finish ();

}

################################################################################

sub handle_request_of_type_action {

	require_content DEFAULT;

	my ($page) = @_;

	my $action = $_REQUEST {action};

	undef $__last_insert_id;

	our %_OLD_REQUEST = %_REQUEST;

	log_action_start ();

	check_dbl_click_start ();

	return action_finish () if $_REQUEST {__response_sent};

	eval { $db -> {AutoCommit} = 0; };

	my $page_type = $page -> {type};

	if ($_REQUEST {__edited_cells_table}) {
		require_content ( $_REQUEST {action_type} )	if $_REQUEST {action_type};

		$page_type = $_REQUEST {action_type} || $page -> {type};
	}

	eval { $_REQUEST {error} = call_for_role ("validate_${action}_$page_type"); };

	$_REQUEST {error} ||= $@ if $@;

	return handle_error ($page) if $_REQUEST {error};

	return action_finish () if $_REQUEST {__response_sent} || $_REQUEST {__peer_server};

	eval {

		call_for_role ("do_${action}_$page_type");

		call_for_role ("recalculate_$page_type") if $action ne 'create';

	};

	$_REQUEST {error} = $@ if $@;

	return handle_error ($page) if $_REQUEST {error};

	if ($_REQUEST {__edited_cells_table}) {

		my $skin = $_REQUEST {__skin};

		$_REQUEST {__skin} = 'TurboMilk';

		setup_skin ();


		eval { $_REQUEST {__page_content} = $page -> {content} = call_for_role (($_REQUEST {id} ? 'get_item_of_' : 'select_') . $page -> {type})};

		$_REQUEST {error} = $@ if $@;

		return handle_error ($page) if $_REQUEST {error};

		my $result = call_for_role (($_REQUEST {id} ? 'draw_item_of_' : 'draw_') . $page -> {type}, $page -> {content});

		$_REQUEST {__skin} = $skin;

		out_json ({html => $result});

		return action_finish ();
	}

	unless ($_REQUEST {__response_sent}) {

		my $redirect_url = $action eq 'delete' && !$_REQUEST {__refresh_tree}? esc_href () :
			create_url (
				action => '',
				id     => $_REQUEST {id},
				__last_scrollable_table_row => $_REQUEST {__last_scrollable_table_row},
				__refresh_tree => uri_escape ($_REQUEST {__refresh_tree}),
			);

		check_dbl_click_finish ($redirect_url);

		redirect ($redirect_url, {kind => 'js', label => $_REQUEST {__redirect_alert}});

	}

	return action_finish ();

}

################################################################################

sub handle_request_of_type_suggest {

	my ($page) = @_;

	setup_skin ();

	our $_SUGGEST_SUB = undef;

	$_REQUEST {__edit} = 1;
	eval { $_REQUEST {__page_content} = $page -> {content} = call_for_role (($_REQUEST {id} ? 'get_item_of_' : 'select_') . $page -> {type})};

	delete $_REQUEST {__read_only};
	call_for_role (($_REQUEST {id} ? 'draw_item_of_' : 'draw_') . $page -> {type}, $page -> {content});

	if ($_SUGGEST_SUB) {

		delete $_REQUEST {id};

		out_html ({}, draw_suggest_page (ref $_SUGGEST_SUB eq 'CODE' ? &$_SUGGEST_SUB () : $_SUGGEST_SUB));

	}

	return handler_finish ();

}

################################################################################

sub setup_page_content {

	my ($page) = @_;

	delete $_REQUEST {__the_table};

	eval { $page -> {content} = call_for_role (($_REQUEST {id} ? 'get_item_of_' : 'select_') . $page -> {type})};

	$@ and return $_REQUEST {error} = $@;

	$_REQUEST {__page_content} = $page -> {content};

}

################################################################################

sub handle_request_of_type_showing {

	my ($page) = @_;

	foreach (qw (js css)) { push @{$_REQUEST {"__include_$_"}}, @{$conf -> {"include_$_"}}}

	$page -> {no_adjust_last_query_string} or adjust_last_query_string ();

	setup_page_content ($page)
		unless ($_REQUEST {__only_menu} || !$_REQUEST_VERBATIM {type} && !$_REQUEST_VERBATIM {__subset});

	return handler_finish () if $_REQUEST {__response_sent} && !$_REQUEST {error};

	out_html ({}, draw_page ($page));

	return handler_finish ();

}

################################################################################

sub handle_request_of_type_data {

	my ($page) = @_;

	setup_skin ();

	require_content DEFAULT;

	eval { $page -> {content} = call_for_role ('get_data_' . $page -> {type}, $page)};

	$_REQUEST {error} ||= $@ if $@;

	return handle_error ($page) if $_REQUEST {error};

	!$_REQUEST {__response_sent} && out_json ($page -> {content});

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

	if ($ENV {FCGI_ROLE}) {

		my $process = $0;
		$process =~ s#(.*/)?([\w\.]+).*#$2#;
		$0 = $process;

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

sub adjust_last_query_string {

	$_REQUEST {sid} && !$_REQUEST {__top} && !$_REQUEST {__only_menu} && $_REQUEST {type} ne '__query' or return;

	my $_PREVIOUS_REQUEST = parse_query_string_to_hashref ($r -> headers_in -> {Referer});

	$_PREVIOUS_REQUEST -> {action}
		or $_REQUEST {__last_query_string} != $_PREVIOUS_REQUEST -> {__last_query_string}
		or $_REQUEST {type}                ne $_PREVIOUS_REQUEST -> {type}
		or $_REQUEST {__next_query_string}
		or $_PREVIOUS_REQUEST -> {__edit}
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

		set_cookie_for_root (user_login => sql_select_scalar ("SELECT login FROM $conf->{systables}->{users} WHERE id = ?", $_USER -> {id}));

		my ($fields, @params);

		$fields = 'ip = ?, ip_fw = ?';
		push (@params, $ENV {REMOTE_ADDR}, $ENV {HTTP_X_FORWARDED_FOR});

		if ($preconf -> {core_fix_tz} && $_REQUEST {tz_offset}) {
			$fields .= ", tz_offset = ?";
			push (@params, $_REQUEST {tz_offset});
		}

		if ($conf -> {core_delegation} && !$_USER -> {id__real}) {
			$fields .= ", id_user_real = ?";
			push (@params, $_USER -> {id});
		}

		unless ($preconf -> {core_no_cookie_check}) {
			$fields .= ", client_cookie = ?";
			push (@params, $_COOKIE {client_cookie});
		}

		sql_do ("UPDATE $conf->{systables}->{sessions} SET $fields WHERE id = ?", @params, $_REQUEST {sid});

		session_access_logs_purge ();

		mbox_refresh ();

	}

	if ($_COOKIE {redirect_params}) {

		my $VAR1;
		eval {$VAR1 = $_JSON -> decode (MIME::Base64::decode ($_COOKIE {redirect_params}));};

		foreach my $key (keys %$VAR1) { $_REQUEST {$key} = $VAR1 -> {$key} }

		set_cookie_for_root (redirect_params => '');

	}

}

1;
