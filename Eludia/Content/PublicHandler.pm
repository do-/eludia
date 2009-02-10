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
			return $ok;
		}

		$r -> content_type ($_REQUEST {__content_type});
		$r -> headers_out -> {'Last-Modified'} = time2str ($time);
		$r -> headers_out -> {'Cache-Control'} = 'max-age=0';
		$r -> headers_out -> {'X-Powered-By'} = 'Eludia/' . $Eludia::VERSION;

		if ($r -> header_only && $time) {

			$r -> send_http_header () unless (MP2);

			$_REQUEST {__response_sent} = 1;
			return $ok;
		}

		my $use_gzip = $preconf -> {core_gzip} && ($r -> headers_in -> {'Accept-Encoding'} =~ /gzip/);

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
			return $ok;
		}

#		if ($html) {
#			$_REQUEST {__is_gzipped} = $use_gzip;
#			out_html ({}, $html);
#			return $ok;
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
			return $ok if $_REQUEST {__response_sent};
			$_PAGE -> {body} = &$renderrer ($content);
		};
		print STDERR $@ if $@;

		my $html = draw_pub_page ();

		if ($conf -> {core_cache_html}) {

			my $gzipped = $preconf -> {core_gzip} ? Compress::Zlib::memGzip ($html) : '';
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