no warnings;

#################################################################################

sub get_request {

	my $http_host = $ENV {HTTP_X_FORWARDED_HOST} || $self -> {preconf} -> {http_host};
	if ($http_host) {
		$ENV {HTTP_HOST} = $ENV {HTTP_X_FORWARDED_HOST};
	}

	if ($connection) {
		our $r   = new Eludia::InternalRequest ($connection, $request);
		our $apr = $r;
		return;
	}
	elsif ($ENV {SERVER_SOFTWARE} =~ /IIS/) {
	        our $r = new Eludia::Request ($preconf, $conf);
		our $apr = $r;
	}
	else {

		our $use_cgi = $ENV {SCRIPT_NAME} =~ m{index\.pl} || ($ENV {GATEWAY_INTERFACE} =~ m{^CGI/} && !$ENV{MOD_PERL}) || $preconf -> {use_cgi} || !$INC{"${Apache}/Request.pm"};
		our $r   = $use_cgi ? new Eludia::Request ($preconf, $conf) : $_[0];
		our $apr = $use_cgi ? $r : ("${Apache}::Request" -> new ($r));

	}

	if (ref $apr eq "${Apache}::Request") {
		eval "require ${Apache}::Cookie";
		our %_COOKIES = "${Apache}::Cookie" -> fetch; # ($r);
	}
	elsif ($ENV {SERVER_SOFTWARE} =~ /IIS/) {
		our %_COOKIES = ();
	}
	else {
		require CGI;
		require CGI::Cookie;
		our %_COOKIES = CGI::Cookie -> fetch;
	}
	

}

#################################################################################

sub setup_skin {

	my ($options) = @_;

	eval {$_REQUEST {__skin} ||= get_skin_name ()};

	unless ($_REQUEST {__skin}) {

		if ($_REQUEST {xls}) {
			$_REQUEST {__skin} = 'XL';
		}
		elsif (($_REQUEST {__dump} || $_REQUEST {__d}) && $preconf -> {core_show_dump}) {
			$_REQUEST {__skin} = 'Dumper';
		}
		elsif ($_REQUEST {__proto}) {
			$_REQUEST {__skin} = 'XMLProto';
		}
		elsif ($_REQUEST {__x}) {
			$_REQUEST {__skin} = 'XMLDumper';
		}
		elsif ($_REQUEST {__windows_ce}) {
			$_REQUEST {__skin} = 'WinCE';
		}

	}

	$_REQUEST {__skin} ||= $preconf -> {core_skin};
	$_REQUEST {__skin} ||= 'Classic';

	$options -> {kind} = 'error' if $_REQUEST {error};

	if ($options -> {kind}) {
		eval "require Eludia::Presentation::Skins::$_REQUEST{__skin}";
		$_REQUEST {__skin} = (${"Eludia::Presentation::Skins::$_REQUEST{__skin}::replacement"} -> {$options->{kind}} ||= $_REQUEST {__skin});
	}

	our $_SKIN = "Eludia::Presentation::Skins::$_REQUEST{__skin}";
	eval "require $_SKIN";
	warn $@ if $@;

	our $_JS_SKIN = "Eludia::Presentation::Skins::JS";
	eval "require $_JS_SKIN";
	warn $@ if $@;
	
	$_REQUEST {__static_site} = '';
	
	if ($preconf -> {static_site}) {
	
		if (ref $preconf -> {static_site} eq CODE) {
		
			$_REQUEST {__static_site} = &{$preconf -> {static_site}} ();
		
		}
		elsif (! ref $preconf -> {static_site}) {

			$_REQUEST {__static_site} = $preconf -> {static_site};

		}
		else {
		
			die "Invalid \$preconf -> {static_site}: " . Dumper ($preconf -> {static_site});
		
		}
			
	}	
	
	$_REQUEST {__static_url}  = '/i/_skins/' . $_REQUEST {__skin};
	$_REQUEST {__static_salt} = $_REQUEST {sid} || rand ();

	$_SKIN -> {options} ||= $_SKIN -> options;

	$_REQUEST {__no_navigation} ||= $_SKIN -> {options} -> {no_navigation};
	
	check_static_files ();
	
	$_REQUEST {__static_url} = $_REQUEST {__static_site} . $_REQUEST {__static_url} if $_REQUEST {__static_site};

	require JSON::XS;

	our $_JSON = JSON::XS -> new -> latin1 (1);
	
	foreach my $package ($_SKIN, $_JS_SKIN) {

		attach_globals ($_PACKAGE => $package, qw(
			_PACKAGE
			_REQUEST
			_USER
			SQL_VERSION
			conf
			preconf
			r
			i18n
			create_url
			_SUBSET
			_JSON
			tree_sort
			adjust_esc
		));

	}

}

#################################################################################

sub check_static_files {

	return if $_SKIN -> {static_ok};
	return if $_SKIN -> {options} -> {no_presentation};
	return if $_SKIN -> {options} -> {no_static};
	$r or return;
	
	my $skin_root = $r -> document_root () . $_REQUEST {__static_url};
		
	-d $skin_root or mkdir $skin_root or die "Can't create $skin_root: $!";

	my $static_path = $_SKIN -> static_path;

	opendir (DIR, $static_path) || die "can't opendir $static_path: $!";
	my @files = readdir (DIR);
	closedir DIR;

	foreach my $src (@files) {
		$src =~ /\.pm$/ or next;
		File::Copy::copy ($static_path . $src, $skin_root . '/' . $`) or die "can't copy ${static_path}${src} to ${skin_root}/${`}: $!";
	}
	
	my $favicon = $r -> document_root () . '/i/favicon.ico';
	
	if (-f $favicon) {
		
		File::Copy::copy ($favicon, $skin_root . '/favicon.ico') or die "can't copy favicon.ico: $!";
		
	}

	my $over_root = $r -> document_root () . '/i/skins/' . $_REQUEST {__skin};

	if (-d $over_root) {

		opendir (DIR, $over_root) || die "can't opendir $over_root: $!";
		my @files = readdir (DIR);
		closedir DIR;

		foreach my $src (@files) {
			$src =~ /\w\.\w+$/ or next;
			File::Copy::copy ($over_root . '/' . $src,  $skin_root . '/' . $src) or die "can't copy $src: $!";
		}

	}
		
	$_SKIN -> {static_ok} = 1;

}

#################################################################################

sub handler {

	my $time = time;
	my $first_time = $time;

	$ENV {REMOTE_ADDR} = $ENV {HTTP_X_REAL_IP} if $ENV {HTTP_X_REAL_IP};

	$_PACKAGE ||= __PACKAGE__ . '::';

	get_request (@_);
		
	my $parms = ref $apr eq 'Apache2::Request' ? $apr -> param : $apr -> parms;
	undef %_REQUEST;
	our %_REQUEST = %{$parms};

	$_REQUEST {__skin} = '';
	our $_REQUEST_TO_INHERIT = undef;

	delete $_REQUEST {__x} if $preconf -> {core_no_xml};

	$_REQUEST {__no_navigation} ||= $_REQUEST {select};

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

		foreach my $key (keys %_REQUEST) {

			$key =~ /^_[^_]/ or next;

			$_REQUEST {$key} =~ s{^\s+}{};
			$_REQUEST {$key} =~ s{\s+$}{};

			if ($key !~ /^_dt/ && $_REQUEST {$key} =~ /^\-?[\d ]*\d([\,\.]\d+)?$/) {

				$_REQUEST {$key} =~ s{ }{}g;
				$_REQUEST {$key} =~ y{,}{.};

				if ($^V ge v5.8.0 && $Math::FixedPrecision::VERSION) {
					$_REQUEST {$field} = new Math::FixedPrecision ($_REQUEST {$field}, ($conf -> {precision} || 3));
				}

			}

		}

	}

	$time = __log_profilinig ($time, '<REQUEST>');
	
	require_config ({no_db => 1});
   	sql_reconnect ();   	
	require_config ();

	$time = __log_profilinig ($time, '<require_config>');
	
	if ($r -> uri =~ m{/(\w+)\.(css|gif|ico|js|html)$}) {

		my $fn = "$1.$2";

		setup_skin ();

		$r -> internal_redirect ("/i/_skins/$_REQUEST{__skin}/$fn");

		return OK;

	}

	if ($preconf -> {core_auth_cookie}) {
		my $c = $_COOKIES {sid};
		$_REQUEST {sid} ||= $c -> value if $c;
	}

	if ($_REQUEST {keepalive}) {
		my $timeout = 60 * $conf -> {session_timeout} - 1;
		$_REQUEST {virgin} or keep_alive ($_REQUEST {keepalive});
		$r -> content_type ('text/html');
		$r -> send_http_header unless (MP2);
		print <<EOH;
			<html><head>
				<META HTTP-EQUIV=Refresh CONTENT="$timeout; URL=$_REQUEST{__uri}?keepalive=$_REQUEST{keepalive}">
			</head></html>
EOH
		return OK;
	}

	if ($_REQUEST {__whois}) {
		my $user = sql_select_hash ("SELECT $conf->{systables}->{users}.id, $conf->{systables}->{users}.label, $conf->{systables}->{users}.mail, $conf->{systables}->{roles}.name AS role FROM $conf->{systables}->{sessions} INNER JOIN $conf->{systables}->{users} ON $conf->{systables}->{sessions}.id_user = $conf->{systables}->{users}.id INNER JOIN $conf->{systables}->{roles} ON $conf->{systables}->{users}.id_role = $conf->{systables}->{roles}.id WHERE $conf->{systables}->{sessions}.id = ?", $_REQUEST {__whois});
		out_html ({}, Dumper ({data => $user}));
		return OK;
	}

	$time = __log_profilinig ($time, '<misc>');

	our $_USER = get_user ();

	$time = __log_profilinig ($time, '<got user>');

	$number_format or our $number_format = Number::Format -> new (%{$conf -> {number_format}});

	$conf -> {__filled_in} or fill_in ();

   	$_REQUEST {__include_js} ||= [];
   	push @{$_REQUEST {__include_js}}, @{$conf -> {include_js}} if $conf -> {include_js};

   	$_REQUEST {__include_css} ||= [];
   	push @{$_REQUEST {__include_css}}, @{$conf -> {include_css}} if $conf -> {include_css};

	if ((!$_USER -> {id} and $_REQUEST {type} ne 'logon' and $_REQUEST {type} ne '_boot')) {

		delete $_REQUEST {sid};
		delete $_REQUEST {salt};
		delete $_REQUEST {_salt};
		delete $_REQUEST {__include_js};
		delete $_REQUEST {__include_css};

		my $type = ($preconf -> {core_skip_boot} || $conf -> {core_skip_boot}) || $_REQUEST {__windows_ce} ? 'logon' : '_boot';

		redirect ("/?type=$type&redirect_params=" . b64u_freeze (\%_REQUEST), kind => 'js', target => '_top');

	}

	elsif (exists ($_USER -> {redirect})) {

		redirect (create_url ());

	}

	elsif ($_REQUEST {keepalive}) {

		redirect ("/\?type=logon&_frame=$_REQUEST{_frame}");

	}
	else {

		require_fresh ("${_PACKAGE}Content::subset");

		our $_SUBSET = call_for_role ('select_subset');
		if ($_SUBSET && $_SUBSET -> {items}) {

			$_SUBSET -> {items} = [ grep {!$_ -> {off}} @{$_SUBSET -> {items}} ];

			if ($preconf -> {subset}) {

				$_SUBSET -> {items} = [ grep {$preconf -> {subset_names} -> {$_ -> {name}}} @{$_SUBSET -> {items}} ];

			}

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


		require_fresh ("${_PACKAGE}Content::menu");

		$_REQUEST {lang} ||= $_USER -> {lang} if $_USER;
		$_REQUEST {lang} ||= $preconf -> {lang} || $conf -> {lang}; # According to NISO Z39.53
		our $i18n = $conf -> {i18n} -> {$_REQUEST {lang}};

		my $menu = call_for_role ('select_menu') || call_for_role ('get_menu');
		
		if (!$_REQUEST {type} && ref $menu eq ARRAY && @$menu > 0) {
		
			my $m = $menu -> [0];					
			
			if ($menu -> [0] -> {href}) {
			
				my $href = $menu -> [0] -> {href};
				
				if (ref $href) {
				
					foreach my $k (keys %$href) {
					
						$_REQUEST {$k} = $href -> {$k}
					
					}
				
				}
				else {
					
					$href =~ s{^/?\?}{};
				
					foreach (split /&/, $href) {
					
						my ($k, $v) = split /=/;	
					
						$_REQUEST {$k} = $v;
					
					}
				
				}
				
			}
			else {
			
				$_REQUEST {type} = $menu -> [0] -> {name};
			
			}
			
		}		
		
		my $page = {
			menu => $menu,
			type => $_REQUEST {type},
		};

		if ($conf -> {core_extensible_menu} && $_USER -> {systems}) {

			foreach my $sys (sort grep {/\w/} split /\,/, $_USER -> {systems}) {
				my @items = ();
				eval {@items = &{"_${sys}_menu"}()};
				push @{$page -> {menu}}, @items;
			}

		}

		call_for_role ('get_page');

		$page -> {menu}   = menu_subset ($page -> {menu}) if $preconf -> {subset} or ($_SUBSET && $_SUBSET -> {items});
		$page -> {subset} = $_SUBSET;

		if (!$page -> {type}) {
			
			sub select_default_type {
				my ($items) = @_;


				foreach my $i (@$items) {

					return
						if ($_REQUEST {type});
					

					next if $i -> {off};
					
					if ($i -> {no_page} && @{$i -> {items}} > 0) {
						select_default_type ($i -> {items});
					}
					
					return
						if ($_REQUEST {type});

					$_REQUEST {type} = $page -> {type}  = $i -> {name};
					
				}

			}
			
			select_default_type ($page -> {menu});
			
		};

		unless ($page -> {type} =~ /^_/) {
			require_fresh ("${_PACKAGE}Content::$$page{type}");
			require_fresh ("${_PACKAGE}Presentation::$$page{type}");
		};

		$_REQUEST {__last_last_query_string} ||= $_REQUEST {__last_query_string};

		my $action = $_REQUEST {action};

		if ($action) {

			undef $__last_insert_id;

			eval { $db -> {AutoCommit} = 0; };

			our %_OLD_REQUEST = %_REQUEST;

			log_action_start ();

			my $sub_name = "validate_${action}_$$page{type}";

			my $error_code = undef;
			eval {	$error_code = call_for_role ($sub_name); };
			$error_code = $@ if $@;

			if ($_USER -> {demo_level} > 0) {
				($action =~ /^execute/ and $$page{type} eq 'logon') or $error_code ||= '»звините, вы работаете в демонстрационном режиме';
			}

			if ($error_code) {
				my $error_message_template = $error_messages -> {"${action}_$$page{type}_${error_code}"} || $error_code;
				$_REQUEST {error} = interpolate ($error_message_template);
			}
			if ($_REQUEST {error}) {
				out_html ({}, draw_page ($page));
			}
			else {

				unless ($_REQUEST {__peer_server}) {

					delete $_REQUEST {__response_sent};

					eval {

						delete_fakes () if $action eq 'create';

						call_for_role ("do_${action}_$$page{type}");

						flix_reindex_record ($_REQUEST {type}, $_REQUEST {id}) if $DB_MODEL -> {tables} -> {$_REQUEST {type}} && $DB_MODEL -> {tables} -> {$_REQUEST {type}} -> {flix_keys};

						if (($action =~ /^execute/) and ($$page{type} eq 'logon') and $_REQUEST {redirect_params}) {

							my $VAR1 = b64u_thaw ($_REQUEST {redirect_params});

							foreach my $key (keys %$VAR1) {
								$_REQUEST {$key} = $VAR1 -> {$key};
							}

						} elsif ($conf -> {core_cache_html}) {
							sql_do ("DELETE FROM $conf->{systables}->{cache_html}");
							my $cache_path = $r -> document_root . '/cache/*';
							$^O eq 'MSWin32' or eval {`rm -rf $cache_path`};
						}

					};

					$_REQUEST {error} = $@ if $@;

				}
				if ($_REQUEST {error}) {
					out_html ({}, draw_page ($page));
				}
				elsif (!$_REQUEST {__response_sent}) {

					if ($action eq 'delete' && $conf -> {core_auto_esc} == 2) {
						esc ({label => $_REQUEST {__redirect_alert}});
					}
					else {

						redirect (
							{
								action => '',
								redirect_params => '',
								__last_scrollable_table_row => $_REQUEST {__last_scrollable_table_row},
							},
							{
								kind => 'js',
								label => $_REQUEST {__redirect_alert},
							}
						);
					}

				}

			}

			eval {
				$db -> commit unless $_REQUEST {error} || $db -> {AutoCommit};
				$db -> {AutoCommit} = 1;
			};

			log_action_finish ();

		}
		else {

#		   	sql_reconnect ();

			if (
				$conf -> {core_auto_esc} == 2 &&
				$_REQUEST {sid} &&
				!$_REQUEST {__top} &&
				(
					$r -> headers_in -> {'Referer'} =~ /action=\w/ ||
					$r -> headers_in -> {'Referer'} !~ /__last_query_string=$_REQUEST{__last_query_string}/ ||
					$r -> headers_in -> {'Referer'} !~ /type=$_REQUEST{type}(\W.*)?$/
				)
			) {

				my ($method, $url) = split /\s+/, $r -> the_request;

				$url =~ s{\&?_?salt=[\d\.]+}{}gsm;
				$url =~ s{\&?sid=\d+}{}gsm;

				my $no = sql_select_scalar ("SELECT no FROM $conf->{systables}->{__access_log} WHERE id_session = ? AND href LIKE ?", $_REQUEST {sid}, $url);

				unless ($no) {
					$no = 1 + sql_select_scalar ("SELECT MAX(no) FROM $conf->{systables}->{__access_log} WHERE id_session = ?", $_REQUEST {sid});
					sql_do ("INSERT INTO $conf->{systables}->{__access_log} (id_session, no, href) VALUES (?, ?, ?)", $_REQUEST {sid}, $no, $url);
				}

				$_REQUEST {__last_query_string} = $no;

				$_REQUEST {__last_last_query_string} ||= $_REQUEST {__last_query_string};

			}

			$r -> headers_out -> {'Expires'} = '-1';

			out_html ({}, draw_page ($page));

		}

	}
	
	if ($_REQUEST {__suicide}) {
		$r -> print (' ' x 8096);
		CORE::exit (0);
	}

	__log_profilinig ($first_time, '<TOTAL>');

	return OK;

}

################################################################################

sub out_html {

	my ($options, $html) = @_;

	$html or return;

	return if $_REQUEST {__response_sent};

	my $time = time;

	if ($conf -> {core_sweep_spaces}) {
		$html =~ s{^\s+}{}gsm;
		$html =~ s{[ \t]+}{ }g;
	}

	unless ($preconf -> {core_no_morons}) {
		$html =~ s{window\.open}{nope}gsm;
	}


	$_REQUEST {__content_type} ||= 'text/html; charset=' . $i18n -> {_charset};

	$r -> content_type ($_REQUEST {__content_type});
	$r -> headers_out -> {'X-Powered-By'} = 'Eludia/' . $Eludia::VERSION;

	if ($] > 5.007) {
		require Encode;
		$html = Encode::encode ('windows-1252', $html);
	}

	$preconf -> {core_mtu} ||= 1500;

	if (
		($conf -> {core_gzip} or $preconf -> {core_gzip}) &&
		400 + length $html > $preconf -> {core_mtu} &&
		($r -> headers_in -> {'Accept-Encoding'} =~ /gzip/)
	) {
		$r -> content_encoding ('gzip');
		unless ($_REQUEST {__is_gzipped}) {
			$html = Compress::Zlib::memGzip ($html);
		}
	}

	$r -> headers_out -> {'Content-Length'} = length $html;

	if ($preconf -> {core_auth_cookie}) {

		set_cookie (
			-name    =>  'sid',
			-value   =>  $_REQUEST {sid} || 0,
			-expires =>  $preconf -> {core_auth_cookie},
			-path    =>  '/',
		)

	}


	$r -> send_http_header unless (MP2);

	$r -> header_only or print $html;

	__log_profilinig ($time, ' <out_html: ' . (length $html) . ' bytes>');
}

#################################################################################

sub pub_handler {

	$_PACKAGE ||= __PACKAGE__ . '::';

	get_request (@_);

	my $parms = $apr -> parms;
	if ($parms -> {debug1} or $r -> uri =~ m{/(navigation\.js|0\.html|0\.gif|eludia\.css)}) {
		handler (@_);
		return OK;
	};
	our %_REQUEST = %{$parms};

	$_REQUEST {__uri} = $r -> uri;

	$_REQUEST {__uri} =~ s{^http://[^/]+}{};
	$_REQUEST {__uri} =~ s{\/\w+\.\w+$}{};

	$_REQUEST {__uri_chomped} = $_REQUEST {__uri};
	$_REQUEST {__uri_chomped} =~ s{/+$}{};

	my $c = $_COOKIES {psid};
	$_REQUEST {sid} = $c -> value if $c;

	$_REQUEST {__content_type} ||= 'text/html; charset=' . ($conf -> {_charset} || 'windows-1251');

	sql_reconnect ();

	eval {
		require_fresh ("${_PACKAGE}Content::pub_users");
		our $_USER = get_public_user ();
	};

	my $cache_key = $_REQUEST {__uri_chomped} . '/' . $r -> args;
	my $cache_fn  = $r -> document_root . '/cache/' . uri_escape ($cache_key, "/.") . '.html';

	if ($conf -> {core_cache_html} && !$_USER -> {id}) {

		my $time = sql_select_scalar ("SELECT UNIX_TIMESTAMP(ts) FROM $conf->{systables}->{cache_html} WHERE uri = ?", $cache_key);

		my $ims = $r -> headers_in -> {"If-Modified-Since"};
		$ims =~ s{\;.*}{};

		if ($ims && $time && (str2time ($ims) >= $time)) {
			$r -> status (304);
			$r -> send_http_header unless (MP2);
			$_REQUEST {__response_sent} = 1;
			return OK;
		}

		$r -> content_type ($_REQUEST {__content_type});
		$r -> headers_out -> {'Last-Modified'} = time2str ($time);
		$r -> headers_out -> {'Cache-Control'} = 'max-age=0';
		$r -> headers_out -> {'X-Powered-By'} = 'Eludia/' . $Eludia::VERSION;

		if ($r -> header_only && $time) {

			$r -> send_http_header () unless (MP2);

			$_REQUEST {__response_sent} = 1;
			return OK;
		}

		my $use_gzip = ($conf -> {core_gzip} or $preconf -> {core_gzip}) && ($r -> headers_in -> {'Accept-Encoding'} =~ /gzip/);

#		my $field = $use_gzip ? 'gzipped' : 'html';
#		my $html = sql_select_scalar ("SELECT $field FROM cache_html WHERE uri = ?", $cache_key);

		my $cache_fn_to_read = $cache_fn;
		if ($use_gzip) {
			$cache_fn_to_read .= '.gz';
			$r -> content_encoding ('gzip');
		}

		if (-f $cache_fn_to_read) {
			$r -> content_type ($_REQUEST {__content_type});
			$r -> headers_out -> {'Content-Length'} = -s $cache_fn_to_read;
			$r -> headers_out -> {'Last-Modified'}  = time2str ($time);
			$r -> headers_out -> {'Cache-Control'}  = 'max-age=0';
			$r -> headers_out -> {'X-Powered-By'}   = 'Eludia/' . $Eludia::VERSION;
			$r -> send_http_header () unless (MP2);

			if (MP2) {
				$r->sendfile($cache_fn_to_read);
			} else {
				open (F, $cache_fn_to_read) or die ("Can't open $cache_fn_to_read: $!\n");
				$r -> send_fd (F);
				close (F);
			}

			$_REQUEST {__response_sent} = 1;
			return OK;
		}

#		if ($html) {
#			$_REQUEST {__is_gzipped} = $use_gzip;
#			out_html ({}, $html);
#			return OK;
#		}

	}

	require_fresh ("${_PACKAGE}Config");
	require_fresh ("${_PACKAGE}Content::pub_page");

	our $_PAGE = select_pub_page ();
	return 0 if $_REQUEST {__response_sent};

	my $type   = $_PAGE -> {type};
	my $id     = $_PAGE -> {id};
	my $action = $_REQUEST {action};

	if ($action) {

		require_fresh ("${_PACKAGE}Content::${type}");

		$_REQUEST {error} = call_for_role ("validate_${action}_${type}");

		if ($_REQUEST {error}) {

#			redirect ("?error=$error_code", {kind => 'http'});

			redirect (
				($_REQUEST {__uri_chomped} . '/?' . join '&', map {"$_=" . uri_escape ($_REQUEST {$_})} grep {/^_[^_]/} keys %_REQUEST) . "&error=$_REQUEST{error}",
				{kind => 'http'},
			);

		}
		else {

			eval { $db -> {AutoCommit} = 0; };

			call_for_role ("do_${action}_${type}");

			flix_reindex_record ($_REQUEST {type}, $_REQUEST {id}) if $DB_MODEL -> {tables} -> {$_REQUEST {type}} && $DB_MODEL -> {tables} -> {$_REQUEST {type}} -> {flix_keys};

			eval {
				$db -> commit unless $_REQUEST {error};
				$db -> {AutoCommit} = 1;
			};

			$_REQUEST {__response_sent} or redirect ({action => ''}, {kind => 'http'});

		}

	}
	else {

		require_fresh ("${_PACKAGE}Presentation::pub_page");

		require_fresh ("${_PACKAGE}Content::$type");
		require_fresh ("${_PACKAGE}Presentation::$type");

		my ($selector, $renderrer) =  $id ?
			("get_item_of_$type", "draw_item_of_$type") :
			("select_$type", "draw_$type");


		eval {
			my $content = &$selector ();
			return OK if $_REQUEST {__response_sent};
			$_PAGE -> {body} = &$renderrer ($content);
		};
		print STDERR $@ if $@;

		my $html = draw_pub_page ();

		if ($conf -> {core_cache_html}) {

			my $gzipped = (($conf -> {core_gzip} or $preconf -> {core_gzip})) ? Compress::Zlib::memGzip ($html) : '';
#			sql_do ('REPLACE INTO cache_html (uri, html, gzipped) VALUES (?, ?, ?)', $cache_key, $html, $gzipped);
			sql_do ("REPLACE INTO $conf->{systables}->{cache_html} (uri) VALUES (?)", $cache_key);

			open (F, ">$cache_fn") or die ("Can't write to $cache_fn: $!\n");
			print F $html;
			close (F);

			if ($gzipped) {
				open (F, ">$cache_fn.gz") or die ("Can't write to $cache_fn.gz: $!\n");
				binmode (F);
				print F $gzipped;
				close (F);
			}

		}

		$r -> headers_out -> {'Last-Modified'} = time2str (time);
		$r -> headers_out -> {'Cache-Control'} = 'max-age=0';

		out_html ({}, $html);

	}

#   	$db -> disconnect;

	return OK;

}


1;
