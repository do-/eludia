no warnings;   

################################################################################

sub check_constants {

	use Carp;

	$| = 1;

	$Data::Dumper::Sortkeys = 1;

	$SIG {__DIE__} = \&Carp::confess;
	
	our $_NON_VOID_PARAMETER_NAMES       = {map {$_ => 1} qw (__last_query_string action select redirect_params)};

	our $_INHERITABLE_PARAMETER_NAMES    = {map {$_ => 1} qw (__this_query_string __last_query_string __last_scrollable_table_row __no_navigation __tree __infty __popup __no_infty)};

	our $_NONINHERITABLE_PARAMETER_NAMES = {map {$_ => 1} qw (lang salt sid password error id___query)};

	our %INC_FRESH = ();	
	
	while (my ($name, $path) = each %INC) {
	
		delete $INC {$name} if $name =~ m{Eludia[\./]}; 
		
	}

}

################################################################################

sub check_versions {

	return if $ENV {ELUDIA_BANNER_PRINTED};

	'$LastChangedDate$' =~ /(\d\d)(\d\d)\-(\d\d)\-(\d\d)/;
	
	$Eludia::VERSION  = "$2.$3.$4";

	'$LastChangedRevision$' =~ /(\d+)/;
	
	$Eludia::VERSION .= ".$1";

	$Eludia_VERSION = $Eludia::VERSION;

	print STDERR <<EOT;

 -------------------------------------------------------

 *****     *    ELUDIA / Perl
     *    *
     *   *
 ********       Version: $Eludia_VERSION
     * *
     **
 *****          Copyright (c) 2002-$1$2 by Eludia
 
 -------------------------------------------------------

EOT

	$ENV {ELUDIA_BANNER_PRINTED} = 1;

}

################################################################################

sub check_web_server {

	print STDERR " check_web_server... ";

	use constant MP2 => (exists $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION} >= 2 or $ENV{MOD_PERL} =~ m{mod_perl/1.99});

	our $Apache = 'Apache';
	
	if ($ENV {MOD_PERL_API_VERSION} >= 2) {
		require Apache2::compat;
		$Apache = 'Apache2';
		$ENV {PERL_JSON_BACKEND} = 'JSON::PP';		
	}
	elsif (MP2) {
		require Apache::RequestRec;
		require Apache::RequestUtil;
		require Apache::RequestIO;
		require Apache::Const;
		require Apache::Upload;
		$ENV {PERL_JSON_BACKEND} = 'JSON::PP';		
	} 
	else {
		$ENV {PERL_JSON_BACKEND} = 'JSON::XS';		
	}
	
	if ($ENV {GATEWAY_INTERFACE} eq 'CGI/') {
	
		eval 'require CGI; require Eludia::Content::HTTP::InternalRequest';
		
	}
	elsif ($ENV {GATEWAY_INTERFACE} =~ m{^CGI/} || $preconf -> {use_cgi}) {
	
		eval 'require CGI; require Eludia::Content::HTTP::Request';
		
	} 
	else {
	
		eval "require ${Apache}::Request";

		if ($@) {
		
			warn "$@\n";

			eval 'require CGI; require Eludia::Content::HTTP::Request';
	
		}
		
	}

	if ($Apache::VERSION) {
		Apache -> push_handlers (PerlChildInitHandler => \&sql_reconnect );
		Apache -> push_handlers (PerlChildExitHandler => \&sql_disconnect);
	}
	
	print STDERR "ok.\n";
		
}

################################################################################

sub start_loading_logging {

	$_NEW_PACKAGE ||= __PACKAGE__;

	print STDERR "\nLoading {\n" . (join ",\n", map {"\t$_"} @$PACKAGE_ROOT) . "\n} => " . $_NEW_PACKAGE . "...\n";

}

################################################################################

sub finish_loading_logging {

	print STDERR "Loading $_NEW_PACKAGE is over.\n\n";

}

################################################################################

sub check_application_directory {

	print STDERR " check_application_directory... ";

	my $docroot;
		
	if (open (IN, $0)) {
	
		my $httpd_conf = join ('', <IN>);
		
		close (IN);
		
		if ($httpd_conf =~ /^\s*DocumentRoot\s+(.*)$/i) {
		
			$docroot = $1;
			
			$docroot =~ s/\"\'//g; #'
			
		}
		
	}
	
	if (!$docroot) {
	
		foreach (@$PACKAGE_ROOT) {
					
			/[\/\\]lib$/ or next;
			
			$docroot = $` . '/docroot';
			
			last;
		
		}
		
	}
	
	if (!$docroot) {
	
		print STDERR "docroot NOT FOUND :-(\n";
		
		return;
	
	}
	
	$docroot =~ s{[\/\\]$}{};
	
	$docroot .= '/';

	print STDERR "$docroot...\n";

	foreach my $subdir ('i/_skins', 'i/upload', 'i/upload/images') {

		print STDERR "  checking ${docroot}${subdir}...";

		my $dir = $docroot . $subdir;

		eval {
		
			-d $dir or mkdir $dir;
	
			chmod 0777, $dir;
			
		};

		warn $@ if $@;

		print STDERR "ok\n";

	}

}

################################################################################

sub check_external_modules {

	use Data::Dumper;
	use Date::Calc;
	use DBI;
	use DBI::Const::GetInfoType;
	use Digest::MD5;
	use Fcntl ':flock';
	use File::Copy 'move';
	use HTML::Entities;
	use HTTP::Date;
	use MIME::Base64;
	use Number::Format;
	use Time::HiRes 'time';
	use Storable;

	check_web_server                           (); 
	check_external_module_math_fixed_precision ();
	check_external_module_zlib                 ();
	check_external_module_uri_escape           ();
	check_external_module_json                 ();
	
}

################################################################################

sub check_external_module_math_fixed_precision {

	print STDERR " check_external_module_math_fixed_precision... ";

	eval { 
		require Math::FixedPrecision;
	};
	
	if ($@) {

		print STDERR "We *strongly* suggest you to install Math::FixedPrecision\n";

	}
	else {
	
		print STDERR "ok\n";

	}

}

################################################################################

sub check_external_module_zlib {

	$preconf -> {core_gzip} or return;

	print STDERR " check_external_module_zlib... ";

	eval 'require Compress::Raw::Zlib';

	if ($@) {
	
		print "Compress::Raw::Zlib is not installed, so gzip encoding will be unavailable.\n";
		
		delete $preconf -> {core_gzip};
		
	}
	else {
	
		print STDERR "ok\n";

	}

}

################################################################################

sub check_external_module_uri_escape {
	
	print STDERR " check_external_module_uri_escape... ";

	eval 'use URI::Escape::XS qw(uri_escape uri_unescape)';

	if ($@) {
	
		print "URI::Escape::XS is, sadly, not installed...";

		eval 'use URI::Escape qw(uri_escape uri_unescape)';
		
		die $@ if $@;
		
	}
	else {
	
		print STDERR "ok\n";

	}
	
}

################################################################################

sub check_external_module_json {
	
	print STDERR " check_external_module_json... ";

	if (MP2) {
	
		eval "require JSON";
		
		if ($@) {
			delete $INC {'JSON.pm'};
			delete $INC {'JSON/PP.pm'};
			delete $INC {'JSON/XS.pm'};
			require JSON::XS;
		}
		
	} 
	else {
	
		eval "require JSON::XS";
		
		if ($@) {
	
			$ENV {PERL_JSON_BACKEND} = 'JSON::PP';			
			require JSON;
			
		}
		
	}

	print STDERR "ok ($ENV{PERL_JSON_BACKEND})\n";
	
}

################################################################################

sub check_internal_modules {

	require Eludia::Content;
	require Eludia::Presentation;
	require Eludia::SQL;
	
	require_config ();

	check_internal_module_peering ();
	check_internal_module_mail    ();
	check_internal_module_ntlm    ();
	check_internal_module_queries ();

}

################################################################################

sub check_internal_module_peering {

	$preconf -> {peer_servers} or return; 
	
	require Eludia::Content::Peering;

}

################################################################################

sub check_internal_module_mail {

	if ($preconf -> {mail}) { 
		
		require Eludia::Content::Mail;
		
	} 
	else { 
		
		eval 'sub send_mail {warn "Mail parameters are not set.\n" }';
		
	}

}

################################################################################

sub check_internal_module_ntlm {

	if ($preconf -> {ldap} -> {ntlm}) { 
		
		require Eludia::Content::Auth::NTLM; 
		
	} 
	else { 
		
		eval 'sub check_auth {}';
		
	}

}

################################################################################

sub check_internal_module_queries {

	if ($conf -> {core_store_table_order}) { 
		
		require Eludia::Content::Queries 
	} 
	else { 
		
		eval 'sub fix___query {}; sub check___query {}'
	
	}

}

################################################################################

BEGIN {

	check_constants             ();
	check_versions              ();

	start_loading_logging       ();

	check_application_directory ();
	check_external_modules      ();
	check_internal_modules      ();

	finish_loading_logging      ();

}

1;

################################################################################

=head1 NAME

Eludia.pm - a framework for rapid (~5 min for trivial CRUD; ~1 h for average complex screen) development and comfortable maintenance of large scale (hundreds of dialog screens) mission critical WEB applications. 

=head1 FEATURES

=over 1

=item *

active DB model: tables are created and altered automatically according to a textual schema definition;

=item *

one shot autoexec scripts making it possible to deploy application updates by simply copying new files;

=item *

rich DHTML (or call it AJAX) widget set available just out-of-the-box;

=item *

i18n with Russian, French and English bootstrap dictionnaries;

=item *

complex server side data validation made easy;

=item *

default handlers for basic CRUD actions;

=item *

automatic support for delete/undelete and merge/unmerge operations;

=item *

transparent logging of all user actions (with parameter values);

=item *

per-session access logging and smart ESC button (like BACK, but works well with data being edited);

=item *

built-in automaintenance tools;

and some more...

=back

=head1 APOLOGIES

Using Eludia.pm requires some learning. We are unable to cite here a short synopsis suitable for copying / pasting and running. Ten lines will show nothing, and for structured content we prefer MediaWiki. Thank you for understanding.

We are really sorry, but it is in Russian only. We know, some people consider this insulting, but, honest, we force nobody to study our language. Writing such a manual en English is not easier to us than learning Russian to you.

Having said that, we humbly invite all Russian-speaking Perl WEB developpers to visit L<http://eludia.ru/wiki>. Volunteer translators are, of course, welcome.

=head1 DISCLAIMER

The authors of Eludia.pm DOES NOT follow certain rules widely considered as "good style" attributes. We DO NOT recommend using Eludia.pm to any person who believe that formal accordance with these rules come first to factual quality and performance. NOR we beg from people who obviously will never use our software for exploring and "assessing" it.

=head1 AUTHORS

Dmitry Ovsyanko, <'do_' -- like this, with a trailing underscore -- at 'pochta.ru'>

Pavel Kudryavtzev

Roman Lobzin

Vadim Stepanov
