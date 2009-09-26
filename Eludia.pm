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
	
	our @_OVERRIDING_PARAMETER_NAMES     = qw (select __no_navigation __tree __last_query_string);

	our %INC_FRESH = ();	
	
	while (my ($name, $path) = each %INC) {
	
		delete $INC {$name} if $name =~ m{Eludia[\./]}; 
		
	}

}

################################################################################

sub check_version_by_git_files {

	require Compress::Raw::Zlib or return;

	-d (my $dir = "$preconf->{core_path}/.git") or return undef;

	open (H, "$dir/HEAD") or return undef;
	
	my $head = <H>; close H;
	
	$head =~ /ref:\s*([\w\/]+)/ or return undef;
	
	open (H, "$dir/$1") or return undef;
	
	$head = <H>; close H;
	
	$head =~ /^([a-f\d]{2})([a-f\d]{5})([a-f\d]{33})/ or return undef;
	
	my $tag = "$1$2";
	
	my $fn = "$dir/objects/$1/$2$3";
	
	open (H, $fn) or return undef;
	
	my $zipped;
	
	read (H, $zipped, -s $fn);
	
	close (H);
	
	length $zipped or return undef;
	
	my ($i, $status) = new Compress::Raw::Zlib::Inflate ();

	$status and return undef;

	$status = $i -> inflate ($zipped, my $src, 1);
	
	foreach (split /\n/, $src) {
	
		/committer.*?(\d+) ([\+\-])(\d{4})$/ or next;
		
		my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime ($1);
		
		return sprintf ("%02d.%02d.%02d.%s", $year - 100, $mon + 1, $mday, $tag);

	}

}

################################################################################

sub check_version_by_git {

	my $cwd = getcwd ();

	chdir $preconf -> {core_path};
	
	my $head = `git show HEAD --abbrev-commit --pretty=medium`;
	
	chdir $cwd;
	
	$head =~ /^commit (\w+).+Date\:\s+\S+\s+(\S+)\s+(\d+)\s[\d\:]+\s(\d+)/sm or return check_version_by_git_files ();
	
        return sprintf ("%02d.%02d.%02d.%s", 
        	$4 - 2000,
        	1 + (index ('JanFebMarAprMayJunJulAugSepOctNovDec', $2) / 3),
        	$3,
        	$1,
        );

}

################################################################################

sub check_version {

	return if $ENV {ELUDIA_BANNER_PRINTED};
	
	use File::Spec;

	my $dir = File::Spec -> rel2abs (__FILE__);
		
	$dir =~ s{Eludia.pm}{};
	
	$preconf -> {core_path} = $dir;

	require Date::Calc;
	
	my ($year) = Date::Calc::Today ();
	
	eval {require Eludia::Version};
	
	$Eludia::VERSION ||= check_version_by_git ();
	
	$Eludia::VERSION ||= 'UNKNOWN (please write some Eludia::Version module)';
	
	my $year;
	
	if ($Eludia::VERSION =~ /^(\d\d)\.\d\d.\d\d/) {
	
		$year = '20' . $1;
	
	}
	else {

		($year) = Date::Calc::Today ();

	}
	
	my $length = 23 + length $Eludia::VERSION;
	
	$length > 49 or $length = 49;
	
	my $bar = '-' x $length;

	print STDERR <<EOT;

 $bar

 *****     *    Eludia.pm
     *    *
     *   *
 ********       Version $Eludia::VERSION
     * *
     **
 *****          Copyright (c) 2002-$year by Eludia
 
 $bar

EOT

	$ENV {ELUDIA_BANNER_PRINTED} = 1;

}

################################################################################

sub check_web_server_apache {

	return if $preconf -> {use_cgi};
	
	my $module = 'Apache';

	$module .= 2 if $ENV {MOD_PERL_API_VERSION} >= 2;
		
	$module .= '::Request';

	print STDERR "\n  mod_perl detected, checking for $module... ";

	my $version = 
		$ENV {MOD_PERL_API_VERSION} >= 2                 ? 2   :
		$ENV {MOD_PERL}              =~ m{mod_perl/1.99} ? 199 :
	                                                           1
	;

	eval "require Eludia::Content::HTTP::API::ModPerl$version";

	if ($@) {

		$preconf -> {use_cgi} = 1;		
		print STDERR "not found; falling back to CGI :-(\n";		
		return;

	}

}

################################################################################

sub check_web_server {

	print STDERR " check_web_server... ";
	
	$ENV {MOD_PERL} or $ENV {MOD_PERL_API_VERSION} or $preconf -> {use_cgi} ||= 1;

	check_web_server_apache ();

	if ($preconf -> {use_cgi}) {
	
		eval "require Eludia::Content::HTTP::API::CGISimple";
		
		if ($@) {

			print STDERR " CGI::Simple is not installed... ";

			eval "require Eludia::Content::HTTP::API::CGI";

		}		
		
	}
		
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

	my $docroot = $ENV{DOCUMENT_ROOT};
		
	if (!$docroot && open (IN, $0)) {
	
		my $httpd_conf = join ('', <IN>);
		
		close (IN);
		
		if ($httpd_conf =~ /^\s*DocumentRoot\s+([\"\'\\\/\w\.\:\- ]+)/gism) {
		
			$docroot = $1;
			
			$docroot =~ s/[\"\']//g; #'
			
		}
		
	}
	
	if (!$docroot) {
	
		foreach (reverse @$PACKAGE_ROOT) {
					
			/[\/\\]lib$/ or next;
			
			$docroot = $` . '/docroot';
			
			last;
		
		}
		
	}
	
	$docroot or die "docroot NOT FOUND :-(\n";
	
	$docroot =~ s{[\/\\]$}{};
	
	$docroot .= '/';

	print STDERR "$docroot...\n";
	
	$preconf -> {_} -> {docroot} = $docroot;

	foreach my $subdir ('i/_skins', 'i/upload', 'i/upload/images', 'dbm', 'session_access_logs', 'i/_mbox', 'i/_mbox/by_user') {

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

	use Cwd;
	use Data::Dumper;
	use DBI;
	use DBI::Const::GetInfoType;
	use Digest::MD5;
	use Fcntl qw(:DEFAULT :flock);
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
	check_external_module_want                 ();
	
}

################################################################################

sub check_external_module_want {

	print STDERR " check_external_module_want................... ";

	eval 'use Want';
	
	if ($@) {

		print STDERR "Please consider installing Want\n";
		
		eval 'sub want {0}';

	}
	else {
	
		print STDERR "Want $Want::VERSION ok.\n";

	}

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
	
		print STDERR "Math::FixedPrecision $Math::FixedPrecision::VERSION ok.\n";

	}

}

################################################################################

sub check_external_module_zlib {

	print STDERR " check_external_module_zlib................... ";

	if (!$preconf -> {core_gzip}) {

		print STDERR "DISABLED, ok\n";

		return;
		
	}

	eval 'require Compress::Raw::Zlib';

	if ($@) {
	
		print "Compress::Raw::Zlib not installed, ok.\n";
		
		delete $preconf -> {core_gzip};
		
	}
	else {
	
		print STDERR "Compress::Raw::Zlib $Compress::Raw::Zlib::VERSION ok.\n";

	}

}

################################################################################

sub check_external_module_uri_escape {
	
	print STDERR " check_external_module_uri_escape............. ";

	eval 'use URI::Escape::XS qw(uri_escape uri_unescape)';

	if ($@) {
	
		eval 'use URI::Escape qw(uri_escape uri_unescape)';
		
		die $@ if $@;

		print STDERR "URI::Escape $URI::Escape::VERSION ok. (URI::Escape::XS suggested)\n";
		
	}
	else {
	
		print STDERR "URI::Escape::XS $URI::Escape::XS::VERSION ok.\n";

	}
	
}

################################################################################

sub check_external_module_json {
	
	print STDERR " check_external_module_json................... ";
	
	unless ($ENV {PERL_JSON_BACKEND}) {
	
		eval "require JSON::XS";
		
		if ($@) {
			
			print STDERR "JSON::XS in not installed :-( ";
			
			$ENV {PERL_JSON_BACKEND} = 'JSON::PP';
			
		}
		else {

			$ENV {PERL_JSON_BACKEND} = 'JSON::XS';

		}
	
	}
	
	eval "require Eludia::Presentation::$ENV{PERL_JSON_BACKEND}";
	
	die $@ if $@;
			
	print STDERR qq{$ENV{PERL_JSON_BACKEND} ${"$ENV{PERL_JSON_BACKEND}::VERSION"} ok.\n};

}

################################################################################

sub check_internal_modules {

	require Eludia::Content;
	require Eludia::Presentation;
	require Eludia::SQL;
	
	require Eludia::GenericApplication::Config;
	
	require_config ();

	check_internal_module_peering             ();
	check_internal_module_mail                ();
	check_internal_module_queries             ();
	check_internal_module_mac                 ();
	check_internal_module_auth                ();
	check_internal_module_checksums           ();
	check_internal_module_session_access_logs ();
	check_internal_module_schedule            ();
	check_internal_module_presentation_tools  ();
	check_internal_module_memory              ();

}

################################################################################

sub check_internal_module_schedule {

	print STDERR " check_internal_module_schedule............... ";
	
	my $crontab = $preconf -> {schedule} -> {crontab};

	unless ($crontab) {

		print STDERR "no crontab, ok.\n";
		
		return;

	}
	
	print STDERR "$crontab... ";
	
	if (-f $crontab) {
	
		print STDERR "exists, ok.\n";
	
	}
	else {
	
		open  (F, ">$crontab") or die "Can't write to $crontab:$!\n";
		print  F '';
		close (F);
		chmod 0600 , $crontab;

		print STDERR "created, ok.\n";

	}

	open  (F, $crontab) or die "Can't open $crontab:$!\n";	
	my @old_lines = (<F>);
	close (F);

	my @paths = ();

	my %script2line = ();

	foreach my $dir (@$PACKAGE_ROOT) {

		print STDERR "  checking $dir for offline script directories...\n";

		my $logdir  = $dir;		
		   $logdir  =~ s{[\\/]+lib[\\/]*$}{};		   		   
		   $logdir .= '/logs';

		-d $logdir or mkdir $logdir;

		foreach my $subdir ('offline', 'Offline') {
		
			my $path = "$dir/$subdir";
			
			-d $path or next;

			print STDERR "   checking $path for scheduled scripts...\n";

			opendir (DIR, $path) or die "can't opendir $path: $!";

			my @file_names = readdir (DIR);

			closedir DIR;

			foreach my $file_name (@file_names) {

				$file_name =~ /\.pl$/ or next;

				print STDERR "    checking $file_name" . ('.' x (43 - length $file_name));

				my $file_path = "$path/$file_name";

				my $the_string = '';

				open  (F, $file_path) or die "Can't open $file_path:$!\n";	

				while (<F>) {

					chomp;

					/^\#\@crontab\s+/ or next;

					$the_string = eval "qq{$'}";
					
					$the_string =~ s{[\n\r]}{}gsm;					

				}

				close (F);

				if ($the_string) {
					
					print STDERR " scheduled at '$the_string', ok\n";

					$the_string .= (' ' x (16 - length $the_string));

					my $inc = File::Spec -> rel2abs (__FILE__);

					$inc =~ s{[\\/]+Eludia.pm}{};

					$script2line {$file_name} = "$the_string perl -I$inc -MEludia::Offline $file_path >> $logdir/$file_name.log 2>\&1\n";

				}
				else {

					print STDERR " not scheduled, ok\n";

				}

			}

		}			
		
		print STDERR "  done with $dir.\n";

	}

	my @new_lines = ();
	
	my @scripts = keys %script2line;
	
	TOP: foreach my $line (@old_lines) {
	
		foreach (@scripts) { next TOP if $line =~ /$_/ }
		
		if ($line !~ /^\#/) {
		
			foreach my $dir (@$PACKAGE_ROOT) {

				foreach my $subdir ('offline', 'Offline') {
				
					$line =~ m{$dir/$subdir/\w+\.pl} or next;
					
					next if -f $&;
					
					print STDERR "    $& not found, will be commented out";
					
					push @new_lines, '# ' . $line;
					
					last TOP;

				}

			}

		}		

		push @new_lines, $line;
	
	}	
	
	my @lines = sort values %script2line;
	
	if (@new_lines == @old_lines and @lines == 0) {
	
		print STDERR "  nothing to do with crontab, ok\n";
		
		return;
	
	}
	
	push @new_lines, @lines;
	
	my $old = join '', @old_lines;
	my $new = join '', @new_lines;

	if ($old eq $new) {
	
		print STDERR "  crontab is not changed, ok\n";
		
		return;
	
	}
	
	open  (F, ">$crontab") or die "Can't write to $crontab:$!\n";
	syswrite (F, $new);
	close (F);

	print STDERR "  crontab is overwritten, ok\n";
	
	my $command = $preconf -> {schedule} -> {command};
	
	if ($command) {

		print STDERR "  reloading schedule...";
		
		print STDERR `$command 2>&1`;
		
		print STDERR " ok.\n";

	}	

}

################################################################################

sub check_internal_module_memory {

	require Eludia::Content::Memory;

}

################################################################################

sub check_internal_module_checksums {

	require Eludia::Content::Checksums;

}

################################################################################

sub check_internal_module_presentation_tools {

	print STDERR " check_internal_module_presentation_tools......";

	require Eludia::Presentation::Tools;

}

################################################################################

sub check_internal_module_mac {

	print STDERR " check_internal_module_mac.................... ";

	exists $preconf -> {core_no_log_mac} or $preconf -> {core_no_log_mac} = 1;
	
	if ($preconf -> {core_no_log_mac}) { 

		eval 'sub get_mac {""}';
		
		print STDERR "no MAC logging, ok.\n";

	} 
	else { 

		require Eludia::Content::Mac;

		print STDERR "MAC logging enabled, ok.\n";		

	}

}

################################################################################

sub check_internal_module_session_access_logs {

	print STDERR " check_internal_module_session_access_logs.... ";

	if ($conf -> {core_session_access_logs_dbtable}) {

		require Eludia::Content::SessionAccessLogs::DBTable;
		
		print STDERR "DBTable, ok.\n";

	} 
	else {

		require Eludia::Content::SessionAccessLogs::File4k;
		
		print STDERR "File4k, ok.\n";

	}
	
}

################################################################################

sub check_internal_module_peering {

	print STDERR " check_internal_module_peering................ ";

	if ($preconf -> {peer_servers}) {
	
		require Eludia::Content::Peering;

		print STDERR "$preconf->{peer_name}, ok.\n";
	
	}
	else {

		eval 'sub check_peer_server {undef}';

		print STDERR "no peering, ok.\n";

	}; 
	
}

################################################################################

sub check_internal_module_mail {

	print STDERR " check_internal_module_mail................... ";

	if ($preconf -> {mail}) { 
		
		require Eludia::Content::Mail;

		print STDERR "$preconf->{mail}->{host}, ok.\n";
		
	} 
	else { 
		
		eval 'sub send_mail {warn "Mail parameters are not set.\n" }';

		print STDERR "no mail, ok.\n";
		
	}

}

################################################################################

sub check_internal_module_auth {

	print STDERR " check_internal_module_auth:\n";
	
	$preconf -> {_} -> {pre_auth}  = [];
	$preconf -> {_} -> {post_auth} = [];

	check_internal_module_auth_cookie ();
	check_internal_module_auth_ntlm ();
	
}

################################################################################

sub check_internal_module_auth_cookie {

	print STDERR "  check_internal_module_auth_cookie........... ";

	if ($preconf -> {core_auth_cookie}) { 
		
		require Eludia::Content::Auth::Cookie; 
		
		print STDERR "$preconf->{core_auth_cookie}, ok.\n";

	} 
	else { 
		
		print STDERR "disabled, ok.\n";
		
	}

}

################################################################################

sub check_internal_module_auth_ntlm {

	print STDERR "  check_internal_module_auth_ntlm............. ";

	if ($preconf -> {ldap} -> {ntlm}) { 
		
		require Eludia::Content::Auth::NTLM; 
		
		print STDERR "$preconf->{ldap}->{ntlm}, ok.\n";

	} 
	else { 

		print STDERR "no NTLM, ok.\n";
		
	}

}

################################################################################

sub check_internal_module_queries {

	print STDERR " check_internal_module_queries................ ";

	if ($conf -> {core_store_table_order}) { 
		
		require Eludia::Content::Queries;

		print STDERR "stored queries enabled, ok.\n";

	} 
	else { 
		
		eval 'sub fix___query {}; sub check___query {}';
	
		print STDERR "no stored queries, ok.\n";

	}

}

################################################################################

BEGIN {

	foreach (grep {/^Eludia/} keys %INC) { delete $INC {$_} }
	
	check_constants             ();
	check_version               ();

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
