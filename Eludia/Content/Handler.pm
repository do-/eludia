#################################################################################

sub get_request {

	my $http_host = $ENV {HTTP_X_FORWARDED_HOST} || $self -> {preconf} -> {http_host};
	
	$ENV {HTTP_HOST} = $http_host if $http_host;

	if ($connection) {
		our $r   = new Eludia::InternalRequest ($connection, $request);
		our $apr = $r;
		return;
	}
	elsif ($ENV {SERVER_SOFTWARE} =~ /IIS/ || $ENV {SERVER_SOFTWARE} =~ /^lighttpd/) {
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

sub handler {

	my $ok = MP2 ? 0 : 200;

	my $handler_time = time ();

	$ENV {REMOTE_ADDR} = $ENV {HTTP_X_REAL_IP} if $ENV {HTTP_X_REAL_IP};

	$_PACKAGE ||= __PACKAGE__ . '::';

	get_request (@_);

	my $time = $r -> request_time ();

	$time = __log_profilinig ($handler_time, '<get_request>');

	my $first_time = $time;

	$_REQUEST {__sql_time} = 0;

	my $parms = ref $apr eq 'Apache2::Request' ? $apr -> param : $apr -> parms;
	undef %_REQUEST;
	our %_REQUEST = %{$parms};
	our $_QUERY = undef;

	$_REQUEST {__skin} = '';
	our $_REQUEST_TO_INHERIT = undef;

	delete $_REQUEST {__x} if $preconf -> {core_no_xml};

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
			
			my $encoded = encode_entities ($_REQUEST {$key}, "ВД-ЙЛС-ЩЫ\xA0§¶І©Ђ-Ѓ∞-±µ-Јї");
			
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
		
	require_config ({no_db => 1});
	
	$time = __log_profilinig ($time, '<require_config no_db>');

   	sql_reconnect ();   	

	$time = __log_profilinig ($time, '<sql_reconnect>');

	require_config ();

	__log_request_profilinig ($request_time);

	$time = __log_profilinig ($time, '<require_config>');
	
	if ($r -> uri =~ m{/(\w+)\.(css|gif|ico|js|html)$}) {

		my $fn = "$1.$2";

		setup_skin ();

		$r -> internal_redirect ("/i/_skins/$_REQUEST{__skin}/$fn");

		return $ok;

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
		return $ok;
	}

	if ($_REQUEST {__whois}) {
		my $user = sql_select_hash ("SELECT $conf->{systables}->{users}.id, $conf->{systables}->{users}.label, $conf->{systables}->{users}.mail, $conf->{systables}->{roles}.name AS role FROM $conf->{systables}->{sessions} INNER JOIN $conf->{systables}->{users} ON $conf->{systables}->{sessions}.id_user = $conf->{systables}->{users}.id INNER JOIN $conf->{systables}->{roles} ON $conf->{systables}->{users}.id_role = $conf->{systables}->{roles}.id WHERE $conf->{systables}->{sessions}.id = ?", $_REQUEST {__whois});
		out_html ({}, Dumper ({data => $user}));
		return $ok;
	}

	$time = __log_profilinig ($time, '<misc>');
	
	check_auth ();

	return $ok if $_REQUEST {__response_sent};

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

		require_content DEFAULT;
		require_content 'subset';

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

		require_content 'menu';

		our $i18n = i18n ();

		my $menu = call_for_role ('select_menu') || call_for_role ('get_menu');
		
		if (!$_REQUEST {type} && ref $menu eq ARRAY && @$menu > 0) {
		
			$menu = [grep {!$_ -> {off}} @$menu];
		
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

		require_both $page -> {type};

		$_REQUEST {__last_last_query_string}   ||= $_REQUEST {__last_query_string};

		my $action = $_REQUEST {action};

		if ($action) {
		
			if ($_REQUEST {__suggest}) {
			
				setup_skin ();

				call_for_role ("draw_item_of_$$page{type}");
				
				delete $_REQUEST {id};
				
				out_html ({}, draw_suggest_page (&$_SUGGEST_SUB ()));
				
				return $ok;
					
				
			}

			undef $__last_insert_id;

			our %_OLD_REQUEST = %_REQUEST;

			log_action_start ();

			eval { $db -> {AutoCommit} = 0; };

			my $sub_name = "validate_${action}_$$page{type}";

			my $error_code = undef;
			eval {	$error_code = call_for_role ($sub_name); };
			$error_code = $@ if $@;
			
			exit if $_REQUEST {__response_sent};

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
						
						call_for_role ("recalculate_$$page{type}") if $action ne 'create';

						if (($action =~ /^execute/) and ($$page{type} eq 'logon') and $_USER -> {id}) {
							set_cookie (
								-name    =>  'user_login',
								-value   =>  sql_select_scalar ("SELECT login FROM $conf->{systables}->{users} WHERE id = ?", $_USER -> {id}),
								-expires =>  '+1M', # 'Sat, 31-Dec-2050 23:59:59 GMT',
								-path    =>  '/',
							);
							
							if ($preconf -> {core_fix_tz} && $_REQUEST {tz_offset}) {
								sql_do ('UPDATE sessions SET tz_offset = ? WHERE id = ?', $_REQUEST {tz_offset}, $_REQUEST {sid});
							}
						}

						if (($action =~ /^execute/) and ($$page{type} eq 'logon') and $_REQUEST {redirect_params}) {
							my $VAR1;
							eval {
								$VAR1 = b64u_thaw ($_REQUEST {redirect_params});
							};
							
							if ($@) {
								warn "b64u_thaw error: $@\n";
							} else {
								foreach my $key (keys %$VAR1) {
									$_REQUEST {$key} = $VAR1 -> {$key};
								}
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

					if ($action eq 'delete') {
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

		}
		else {
		
			if ($_REQUEST {sid} && !$_REQUEST {__top} && !$_REQUEST {__only_menu} && $_REQUEST {type} ne '__query') {
						
				my @qs = split /\?/, $r -> headers_in -> {Referer};
				
				my %p = ();
				
				foreach (split /\&/, $qs [-1]) {
				
					my ($k, $v) = split /\=/;
					
					$p {$k} = $v;
				
				}

#				if ($_REQUEST {__this_query_string} && $_REQUEST {id}) {
					
#					$_REQUEST {__last_last_query_string} ||= $_REQUEST {__last_query_string};
#					$_REQUEST {__last_query_string}        = $_REQUEST {__this_query_string};
					
#				}
				if (
					$p {action} 
					|| $_REQUEST {__next_query_string}
					|| $p {__last_query_string} != $_REQUEST{__last_query_string}
					|| $p {type} ne $_REQUEST {type}
				) {

					my ($method, $url) = split /\s+/, $r -> the_request;
					
					if ($url !~ /\bsid=\d/) {
						
						$url .= '?';
						
						foreach my $k (keys %{$parms}) {
						
							next if $parms -> {$k} eq '';
								
							$url .= "$k=";
							$url .= uri_escape ($parms -> {$k});
							$url .= "&";
								
						}
						
						chop $url;
						
					}

					$url =~ s{\&?_?salt=[\d\.]+}{}gsm;
					$url =~ s{\&?sid=\d+}{}gsm;
					$url =~ s{\&?id___query=\d+}{}gsm;
					$url =~ s{\&?__next_query_string=\d+}{}gsm;

					my $no = sql_select_scalar ("SELECT no FROM $conf->{systables}->{__access_log} WHERE id_session = ? AND href LIKE ?", $_REQUEST {sid}, $url);

					unless ($no) {
						$no = 1 + sql_select_scalar ("SELECT MAX(no) FROM $conf->{systables}->{__access_log} WHERE id_session = ?", $_REQUEST {sid});
						sql_do ("INSERT INTO $conf->{systables}->{__access_log} (id_session, no, href) VALUES (?, ?, ?)", $_REQUEST {sid}, $no, $url);
					}

					$_REQUEST {__last_query_string} = $no;

					$_REQUEST {__last_last_query_string} ||= $_REQUEST {__last_query_string};
				
				}

			}

			$r -> headers_out -> {'Expires'} = '-1';
			
			out_html ({}, draw_page ($page));

		}

	}

	$r -> pool -> cleanup_register (\&__log_request_finish_profilinig, {
		id_request_log		=> $_REQUEST {_id_request_log}, 

		out_html_time		=> $_REQUEST {__out_html_time},
		application_time	=> 1000 * (time - $first_time) - $_REQUEST {__sql_time}, 
		sql_time		=> $_REQUEST {__sql_time},
		is_gzipped		=>  $_REQUEST {__is_gzipped},
		
	}) if $preconf -> {core_debug_profiling} > 2;
	
	if ($_REQUEST {__suicide}) {
		$r -> print (' ' x 8096);
		CORE::exit (0);
	}

	__log_profilinig ($first_time, '<TOTAL>');

	return $ok;

}

1;