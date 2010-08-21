no warnings;   

use Carp;
use Cwd;
use Data::Dumper;
use DBI;
use DBI::Const::GetInfoType;
use Digest::MD5;
use Encode;
use Fcntl qw(:DEFAULT :flock);
use File::Copy 'move';
use HTML::Entities;
use HTTP::Date;
use MIME::Base64;
use Number::Format;
use Time::HiRes 'time';
use Scalar::Util;
use Storable;

################################################################################

sub loading_log (@) {

	$ENV {ELUDIA_SILENT} or print STDERR @_;

}

################################################################################

sub check_constants {

	$| = 1;

	$Data::Dumper::Sortkeys = 1;

	$SIG {__DIE__} = \&Carp::confess;
	
	our $_NON_VOID_PARAMETER_NAMES       = {map {$_ => 1} qw (__last_query_string action select redirect_params)};

	our $_INHERITABLE_PARAMETER_NAMES    = {map {$_ => 1} qw (__this_query_string __last_query_string __last_scrollable_table_row __no_navigation __tree __infty __popup __no_infty)};

	our $_NONINHERITABLE_PARAMETER_NAMES = {map {$_ => 1} qw (lang salt sid password error id___query)};
	
	our @_OVERRIDING_PARAMETER_NAMES     = qw (select __no_navigation __tree __last_query_string);

	our %INC_FRESH = ();
	our %INC_FRESH_BY_PATH = ();

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
	
	use File::Spec;

	my $dir = File::Spec -> rel2abs (__FILE__);
		
	$dir =~ s{Eludia.pm}{};
	
	$dir =~ y{\\}{/};
	
	$preconf -> {core_path} = $dir;

	require Date::Calc;

	return if $Eludia::VERSION ||= $ENV {ELUDIA_BANNER_PRINTED};
	
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

	loading_log <<EOT;

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

	$ENV {ELUDIA_BANNER_PRINTED} = $Eludia::VERSION;

}

################################################################################

sub check_web_server_apache {

	return if $preconf -> {use_cgi};
	
	my $module = 'Apache';

	$module .= 2 if $ENV {MOD_PERL_API_VERSION} >= 2;
		
	$module .= '::Request';

	loading_log "\n  mod_perl detected, checking for $module... ";

	my $version = 
		$ENV {MOD_PERL_API_VERSION} >= 2                 ? 2   :
		$ENV {MOD_PERL}              =~ m{mod_perl/1.99} ? 199 :
	                                                           1
	;

	eval "require Eludia::Content::HTTP::API::ModPerl$version";

	if ($@) {

		$preconf -> {use_cgi} = 1;		
		loading_log "not found; falling back to CGI :-(\n";		
		return;

	}

}

################################################################################

sub check_web_server {

	loading_log " check_web_server... ";
	
	$ENV {MOD_PERL} or $ENV {MOD_PERL_API_VERSION} or $preconf -> {use_cgi} ||= 1;

	check_web_server_apache ();

	if ($preconf -> {use_cgi}) {
	
		eval "require Eludia::Content::HTTP::API::CGISimple";
		
		if ($@) {

			loading_log " CGI::Simple is not installed... ";

			eval "require Eludia::Content::HTTP::API::CGI";

		}		
		
	}
		
}

################################################################################

sub start_loading_logging {

	$_NEW_PACKAGE ||= __PACKAGE__;

	loading_log "\nLoading {\n" . (join ",\n", map {"\t$_"} @$PACKAGE_ROOT) . "\n} => " . $_NEW_PACKAGE . "...\n";

}

################################################################################

sub finish_loading_logging {

	loading_log "Loading $_NEW_PACKAGE is over.\n\n";

}

################################################################################

sub check_application_directory {

	loading_log " check_application_directory... ";

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

	loading_log "$docroot...\n";
	
	$preconf -> {_} -> {docroot} = $docroot;

	foreach my $subdir ('i/_skins', 'i/upload', 'i/upload/images', 'dbm', 'session_access_logs', 'i/_mbox', 'i/_mbox/by_user') {

		loading_log "  checking ${docroot}${subdir}...";

		my $dir = $docroot . $subdir;

		eval {
		
			-d $dir or mkdir $dir;
	
			chmod 0777, $dir;
			
		};

		warn $@ if $@;

		loading_log "ok\n";

	}

}

################################################################################

sub check_module_want {

	loading_log " check_module_want................... ";

	eval 'use Want';
	
	if ($@) {

		loading_log "no Want.pm, ok. [INSTALL SUGGESTED]\n";
		
		eval 'sub want {0}';

	}
	else {
	
		loading_log "Want $Want::VERSION ok.\n";

	}

}

################################################################################

sub check_module_math_fixed_precision {

	loading_log " check_module_math_fixed_precision... ";

	eval { 
		require Math::FixedPrecision;
	};
	
	if ($@) {

		loading_log "no Math::FixedPrecision, ok. [INSTALL SUGGESTED]\n";

	}
	else {
	
		loading_log "Math::FixedPrecision $Math::FixedPrecision::VERSION ok.\n";

	}

}

################################################################################

sub check_module_zlib {

	loading_log " check_module_zlib................... ";

	if (!$preconf -> {core_gzip}) {

		loading_log "DISABLED, ok\n";

		return;
		
	}

	eval 'require Compress::Raw::Zlib';

	if ($@) {
	
		print "no Compress::Raw::Zlib, ok. [INSTALL SUGGESTED]\n";
		
		delete $preconf -> {core_gzip};
		
	}
	else {
	
		loading_log "Compress::Raw::Zlib $Compress::Raw::Zlib::VERSION ok.\n";

	}

}

################################################################################

sub check_module_uri_escape {
	
	loading_log " check_module_uri_escape............. ";

	eval 'use URI::Escape::XS qw(uri_escape uri_unescape)';

	if ($@) {
	
		eval 'use URI::Escape qw(uri_escape uri_unescape)';
		
		die $@ if $@;

		loading_log "URI::Escape $URI::Escape::VERSION ok. [URI::Escape::XS SUGGESTED]\n";
		
	}
	else {
	
		loading_log "URI::Escape::XS $URI::Escape::XS::VERSION ok.\n";

	}
	
}

################################################################################

sub check_module_json {
	
	loading_log " check_module_json................... ";
	
	unless ($ENV {PERL_JSON_BACKEND}) {
	
		eval "require JSON::XS";
		
		if ($@) {
			
			loading_log "JSON::XS in not installed :-( ";
			
			$ENV {PERL_JSON_BACKEND} = 'JSON::PP';
			
		}
		else {

			$ENV {PERL_JSON_BACKEND} = 'JSON::XS';

		}
	
	}
	
	eval "require Eludia::Presentation::$ENV{PERL_JSON_BACKEND}";
	
	die $@ if $@;
			
	loading_log qq{$ENV{PERL_JSON_BACKEND} ${"$ENV{PERL_JSON_BACKEND}::VERSION"} ok.\n};

}

################################################################################

sub check_module_schedule {

	loading_log " check_module_schedule............... ";
	
	my $crontab = $preconf -> {schedule} -> {crontab};

	unless ($crontab) {

		loading_log "no crontab, ok.\n";
		
		return;

	}
	
	loading_log "$crontab... ";
	
	if (-f $crontab) {
	
		loading_log "exists, ok.\n";
	
	}
	else {
	
		open  (F, ">$crontab") or die "Can't write to $crontab:$!\n";
		print  F '';
		close (F);
		chmod 0600 , $crontab;

		loading_log "created, ok.\n";

	}

	open  (F, $crontab) or die "Can't open $crontab:$!\n";	
	my @old_lines = (<F>);
	close (F);

	my @paths = ();

	my %script2line = ();

	foreach my $dir (@$PACKAGE_ROOT) {

		loading_log "  checking $dir for offline script directories...\n";

		my $logdir  = $dir;		
		   $logdir  =~ s{[\\/]+lib[\\/]*$}{};		   		   
		   $logdir .= '/logs';

		-d $logdir or mkdir $logdir;

		foreach my $subdir ('offline', 'Offline') {
		
			my $path = "$dir/$subdir";
			
			-d $path or next;

			loading_log "   checking $path for scheduled scripts...\n";

			opendir (DIR, $path) or die "can't opendir $path: $!";

			my @file_names = readdir (DIR);

			closedir DIR;

			foreach my $file_name (@file_names) {

				$file_name =~ /\.pl$/ or next;

				loading_log "    checking $file_name" . ('.' x (43 - length $file_name));

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
					
					loading_log " scheduled at '$the_string', ok\n";

					$the_string .= (' ' x (16 - length $the_string));

					my $inc = File::Spec -> rel2abs (__FILE__);

					$inc =~ s{[\\/]+Eludia.pm}{};

					$script2line {$file_name} = "$the_string perl -I$inc -MEludia::Offline $file_path >> $logdir/$file_name.log 2>\&1\n";

				}
				else {

					loading_log " not scheduled, ok\n";

				}

			}

		}			
		
		loading_log "  done with $dir.\n";

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
					
					loading_log "    $& not found, will be commented out";
					
					push @new_lines, '# ' . $line;
					
					last TOP;

				}

			}

		}		

		push @new_lines, $line;
	
	}	
	
	my @lines = sort values %script2line;
	
	if (@new_lines == @old_lines and @lines == 0) {
	
		loading_log "  nothing to do with crontab, ok\n";
		
		return;
	
	}
	
	push @new_lines, @lines;
	
	my $old = join '', @old_lines;
	my $new = join '', @new_lines;

	if ($old eq $new) {
	
		loading_log "  crontab is not changed, ok\n";
		
		return;
	
	}
	
	open  (F, ">$crontab") or die "Can't write to $crontab:$!\n";
	syswrite (F, $new);
	close (F);

	loading_log "  crontab is overwritten, ok\n";
	
	my $command = $preconf -> {schedule} -> {command};
	
	if ($command) {

		loading_log "  reloading schedule...";
		
		loading_log `$command 2>&1`;
		
		loading_log " ok.\n";

	}	

}

################################################################################

sub check_module_memory {

	loading_log " check_module_memory................. ";

	require Eludia::Content::Memory;

}

################################################################################

sub check_module_checksums {

	require Eludia::Content::Checksums;

}

################################################################################

sub check_module_presentation_tools {

	loading_log " check_module_presentation_tools..... ";

	require Eludia::Presentation::Tools;

}

################################################################################

sub check_module_session_access_logs {

	loading_log " check_module_session_access_logs.... ";

	if ($conf -> {core_session_access_logs_dbtable}) {

		require Eludia::Content::SessionAccessLogs::DBTable;
		
		loading_log "DBTable, ok.\n";

	} 
	else {

		require Eludia::Content::SessionAccessLogs::File4k;
		
		loading_log "File4k, ok.\n";

	}
	
}

################################################################################

sub check_module_peering {

	loading_log " check_module_peering................ ";

	if ($preconf -> {peer_servers}) {
	
		require Eludia::Content::Peering;

		loading_log "$preconf->{peer_name}, ok.\n";
	
	}
	else {

		eval 'sub check_peer_server {undef}';

		loading_log "no peering, ok.\n";

	}; 
	
}

################################################################################

sub check_module_mail {

	loading_log " check_module_mail................... ";

	if ($preconf -> {mail}) { 
		
		require Eludia::Content::Mail;

		loading_log "$preconf->{mail}->{host}, ok.\n";
		
	} 
	else { 
		
		eval 'sub send_mail {warn "Mail parameters are not set.\n" }';

		loading_log "no mail, ok.\n";
		
	}

}

################################################################################

sub check_module_auth {

	loading_log " check_module_auth:\n";
	
	$preconf -> {_} -> {pre_auth}  = [];
	$preconf -> {_} -> {post_auth} = [];

	check_module_auth_cookie  ();
	check_module_auth_ntlm    ();
	check_module_auth_opensso ();
	check_module_auth_tinysso ();
	
}

################################################################################

sub check_module_auth_cookie {

	loading_log "  check_module_auth_cookie........... ";

	if ($preconf -> {core_auth_cookie}) { 
		
		require Eludia::Content::Auth::Cookie; 
		
		loading_log "$preconf->{core_auth_cookie}, ok.\n";

	} 
	else { 
		
		loading_log "disabled, ok.\n";
		
	}

}

################################################################################

sub check_module_auth_opensso {

	loading_log "  check_module_auth_opensso.......... ";

	if ($preconf -> {ldap} -> {opensso}) { 
		
		require Eludia::Content::Auth::OpenSSO; 
		
		loading_log "$preconf->{ldap}->{opensso}, ok.\n";

	} 
	else { 

		loading_log "no OpenSSO, ok.\n";
		
	}

}

################################################################################

sub check_module_auth_tinysso {

	loading_log "  check_module_auth_tinysso.......... ";

	if ($preconf -> {ldap} -> {tinysso}) { 
		
		require Eludia::Content::Auth::TinySSO; 
		
		loading_log "$preconf->{ldap}->{tinysso}, ok.\n";

	} 
	else { 

		loading_log "no TinySSO, ok.\n";
		
	}

}

################################################################################

sub check_module_auth_ntlm {

	loading_log "  check_module_auth_ntlm............. ";

	if ($preconf -> {ldap} -> {ntlm}) { 
		
		require Eludia::Content::Auth::NTLM; 
		
		loading_log "$preconf->{ldap}->{ntlm}, ok.\n";

	} 
	else { 

		loading_log "no NTLM, ok.\n";
		
	}

}

################################################################################

sub check_module_queries {

	loading_log " check_module_queries................ ";

	if ($conf -> {core_store_table_order}) { 
		
		require Eludia::Content::Queries;

		loading_log "stored queries enabled, ok.\n";

	} 
	else { 
		
		eval 'sub fix___query {}; sub check___query {}';
	
		loading_log "no stored queries, ok.\n";

	}

}

################################################################################

sub check_module_log {

	loading_log " check_module_log.................... ";
	
	$conf -> {core_log} -> {version} ||= 'v1';
	
	$preconf -> {core_log} -> {suppress} ||= {
	
		always => [qw (
		
			__infty
			__last_query_string
			__last_scrollable_table_row
			__no_infty
			__no_navigation
			__popup
			__this_query_string
			redirect_params
			sid
			lang
			salt

		)],
		
		empty  => [qw (
		
			__form_checkboxes
			__suggest
			__tree
			select
			
		)],
	
	};
	
	$preconf -> {_} -> {core_log} = $conf -> {core_log};

	!exists $preconf -> {core_no_log_mac}

		or $preconf -> {core_no_log_mac}

			or $preconf -> {_} -> {core_log} -> {log_mac} = 1;

	require "Eludia/Content/Log/$preconf->{_}->{core_log}->{version}.pm";
	
	loading_log "$preconf->{_}->{core_log}->{version}, ok.\n";

}

#############################################################################

sub darn ($) {warn Dumper ($_[0]); return $_[0]}

################################################################################

BEGIN {

	foreach (grep {/^Eludia/} keys %INC) { delete $INC {$_} }
	
	check_constants             ();
	check_version               ();

	start_loading_logging       ();

	check_application_directory ();
	check_web_server            (); 
	
	require "Eludia/$_.pm" foreach qw (Content Presentation SQL GenericApplication/Config);

	require_config              ();
	
	&{"check_module_$_"}        () foreach sort grep {!/^_/} keys %{$conf -> {core_modules}};

	finish_loading_logging      ();

}

package Eludia;

1;

__END__

################################################################################

=head1 NAME

Eludia - a non-OO MVC.

=head1 WARNING

We totally neglect most of so called 'good style' conventions. We do find it really awkward and quite useless.

=head1 APOLOGIES

The project is deeply documented (L<http://eludia.ru/wiki>), but, sorry, in Russian only.

=head1 AUTHORS

Dmitry Ovsyanko

Pavel Kudryavtzev

Roman Lobzin

Vadim Stepanov