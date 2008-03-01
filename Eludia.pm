no warnings; 

use Carp;
use Data::Dumper;
use DBI;
use DBI::Const::GetInfoType;
use Digest::MD5;
use Fcntl ':flock';
use File::Copy 'move';
use File::Find;
use HTTP::Date;
use HTTP::Request::Common;
use LWP::UserAgent;
use MIME::Base64;
use Number::Format;
use Time::HiRes 'time';
use URI::Escape;
use Storable;
use Net::SMTP;
 
use constant MP2 => (exists $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION} >= 2 or $ENV{MOD_PERL} =~ m{mod_perl/1.99}); 

BEGIN {

	our $Apache = 'Apache';
	
	if ($ENV{MOD_PERL_API_VERSION} >= 2) {
		require Apache2::compat;
		$Apache = 'Apache2';
		$ENV{PERL_JSON_BACKEND} = 'JSON::PP'		
	}
	elsif (MP2) {
		require Apache::RequestRec;
		require Apache::RequestUtil;
		require Apache::RequestIO;
		require Apache::Const;
		require Apache::Upload;
		$ENV{PERL_JSON_BACKEND} = 'JSON::PP'		
	} else {
		require Apache::Constants;
		Apache::Constants->import(qw(OK));
		$ENV{PERL_JSON_BACKEND} = 'JSON::XS'		
	}
  
	$Data::Dumper::Sortkeys = 1;
	
	'$LastChangedDate$' =~ /(\d\d)(\d\d)\-(\d\d)\-(\d\d)/;
	
	my $year = "$1$2";

	$Eludia::VERSION      = "$2.$3.$4";

	'$LastChangedRevision$' =~ /(\d+)/;
	
	$Eludia::VERSION     .= ".$1";

	$Eludia_VERSION = $Eludia::VERSION;

	eval {
		require Math::FixedPrecision;
	};
	
	unless ($preconf -> {core_path}) {
		require Eludia::Apache;
		require Eludia::Flix;
		require Eludia::Content;
		require Eludia::Validators;
		require Eludia::InternalRequest;
		require Eludia::Presentation;
		require Eludia::Request;
		require Eludia::Request::Upload;
		require Eludia::SQL;
		require Eludia::FileDumpHash;
		$preconf -> {core_path} = __FILE__;
	}
		
	$| = 1;

	$SIG {__DIE__} = \&Carp::confess;
	
	unless ($PACKAGE_ROOT) {
		$PACKAGE_ROOT = $INC {__PACKAGE__ . '/Config.pm'} || '';
		$PACKAGE_ROOT =~ s{\/Config\.pm}{};
		$PACKAGE_ROOT = [$PACKAGE_ROOT];
	}

	my $_PACKAGE = $_NEW_PACKAGE ? $_NEW_PACKAGE : __PACKAGE__;

	my $pkg_banner = '[' . (join ',', @$PACKAGE_ROOT) . '] => ' . $_PACKAGE;
		
	my $docroot = $PACKAGE_ROOT -> [0];
	$docroot =~ s{/lib(/.*)?}{/docroot/i/};
	
	if (open (IN, $0)) {
		my $httpd_conf = join ('', <IN>);
		close (IN);
		if ($httpd_conf =~ /^\s*DocumentRoot\s+$/mi) {
			$docroot = $';
			$docroot =~ s/\"\'//g; #'"						
		}
		
	}

	if ($docroot) {

		foreach my $subdir ('_skins', 'upload/dav_rw', 'upload/dav_ro', 'upload/images') {

			my $dir = $docroot . $subdir;

			eval {
				-d $dir or mkdir $dir;
				chmod 0777, $dir;
			};

			warn $@ if $@;

		}

	}
	

	if ($preconf -> {subset}) {
		
		my $fn = $PACKAGE_ROOT -> [0] . '/Model/Subsets/' . $preconf -> {subset} . '.txt';
		
		open I, $fn or die "Can't open $fn:$!\n";
		
		while (<I>) {
			s{[\n\r]}{}gsm;
			$preconf -> {subset_names} -> {$_} = 1;
		}
		
		close I;
		
		$pkg_banner .= ' / ';
		$pkg_banner .= $preconf -> {subset};
		
	}


	our $_NON_VOID_PARAMETER_NAMES = {
		__last_query_string => 1,
		action => 1,
		select => 1,
		redirect_params => 1,
	};

	our $_INHERITABLE_PARAMETER_NAMES = {
		__last_query_string => 1,
		__last_scrollable_table_row => 1,
		__no_navigation => 1,
		__tree => 1,
		__infty => 1,
		__no_infty => 1,
	};

	our $_NONINHERITABLE_PARAMETER_NAMES = {
		lang => 1,
		salt => 1,
		sid => 1,
		password => 1,
		error => 1,
	};
			
	unless ($ENV {ELUDIA_BANNER_PRINTED}) {

		print STDERR "\n";
		print STDERR " -------------------------------------------------------\n";
		print STDERR "\n";
		print STDERR " *****     *    ELUDIA / Perl\n";
		print STDERR "     *    *\n";
		print STDERR "     *   *\n";
		print STDERR " ********       Version: $Eludia_VERSION\n";
		print STDERR "     * *\n";
		print STDERR "     **\n";
		print STDERR " *****          Copyright (c) 2002-$year by Eludia\n";
		print STDERR "\n";
		print STDERR " -------------------------------------------------------\n\n";

		$ENV {ELUDIA_BANNER_PRINTED} = 1;

	}

	print STDERR " Loading $pkg_banner...";
	
	unless ($preconf -> {no_model_update}) {
		require DBIx::ModelUpdate;
	}

	if ($ENV {GATEWAY_INTERFACE} =~ m{^CGI/} || $preconf -> {use_cgi}) {
		eval 'require CGI';
	} else {
		eval "require ${Apache}::Request";

		if ($@) {
			warn "$@\n";

			eval 'require CGI';
			eval 'require Eludia::Request';
		}
	}

	eval 'require Eludia::Request' unless ($INC {'Apache/Request.pm'});

	eval 'require Compress::Zlib';
	if ($@) {
		delete $conf -> {core_gzip};
		delete $preconf -> {core_gzip};
	};

	if (MP2) {
		eval "require JSON";
		if ($@) {
			delete $INC {'JSON.pm'};
			delete $INC {'JSON/PP.pm'};
			delete $INC {'JSON/XS.pm'};
			require JSON::XS;
		}
	} else {
		require JSON::XS;
	}

	our %INC_FRESH = ();	
	while (my ($name, $path) = each %INC) {
		delete $INC {$name} if $name =~ m{Eludia[\./]}; 
	}
	
	require_config ();

	if ($preconf -> {core_load_modules}) {
	
		my @files = ("Content/menu.pm", "Content/logon.pm", "Presentation/logon.pm");
				
		if ($conf -> {auto_load}) {
			
			foreach my $type (@{$conf -> {auto_load}}) {				
				push @files, "${_PACKAGE}/Content/$type.pm";
				push @files, "${_PACKAGE}/Presentation/$type.pm";
			}
						
		}
		else {
		
			foreach my $path (reverse (@$PACKAGE_ROOT)) {
			
				foreach my $dir ('Content', 'Presentation') {

					opendir (DIR, "$path/$dir") || die "can't opendir $path/$dir: $!";
					push @files, grep {/\.pm$/} map { "${_PACKAGE}/$dir/$_" } readdir (DIR);
					closedir DIR;	

				}

			}
						
		}

		foreach my $file (@files) {
			$file =~ s{\.pm$}{};
			$file =~ s{\/}{\:\:}g;
			require_fresh ($file);
		}
				
	}
	
	if ($Apache::VERSION) {
		Apache -> push_handlers (PerlChildInitHandler => \&sql_reconnect );
		Apache -> push_handlers (PerlChildExitHandler => \&sql_disconnect);
	}

	print STDERR "\r Loading $pkg_banner ok.\n";

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

Using Eludia.pm requires some learning. We are unable to cite here a short synopsis suitable for copying / pasting and running. Ten lines will show nothing, and for structured content we prefer DocBook to POD. Thank you for understanding.

We wrote an application developer manual. It is ~400K of DocBook sources, ~2M PDF, ~1.2M HTML Help, online version is of course available. An illustrated step-by-step crash course for newbies is included.

But, sorry, we are really sorry, it is in Russian only. We know, some people consider this insulting, but, honest, we force nobody to study our language. Writing such a manual en English is not easier to us than learning Russian to you.

Having said that, we humbly invite all Russian-speaking Perl WEB developpers to visit L<http://eludia.ru/wiki>.

=back

=head1 DISCLAIMER

The authors of Eludia.pm DOES NOT follow certain rules widely considered as "good style" attributes. We DO NOT recommend using Eludia.pm to any person who believe that formal accordance with these rules come first to factual quality and performance. NOR we beg from people who obviously will never use our software for exploring and "assessing" it.

=back

=head1 AUTHORS

Dmitry Ovsyanko, <'do_' -- like this, with a trailing underscore -- at 'pochta.ru'>

Pavel Kudryavtzev

Roman Lobzin
