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
#use Math::FixedPrecision;

use constant MP2 => ( exists $ENV{MOD_PERL_API_VERSION} and 
                        $ENV{MOD_PERL_API_VERSION} >= 2 or $ENV{MOD_PERL} =~ m{mod_perl/1.99}); 

BEGIN {	
	if (MP2) {
		require Apache::RequestRec;
		require Apache::RequestUtil;
		require Apache::RequestIO;
		require Apache::Const;
		require Apache::Upload;
	} else {
		require Apache::Constants;
		Apache::Constants->import(qw(OK));
	}
  
	$Data::Dumper::Sortkeys = 1;

	$Eludia_VERSION      = $Eludia::VERSION      = '07.04.02';
	$Eludia_VERSION_NAME = $Eludia::VERSION_NAME = 'Again';
		
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
	
	if ($docroot) {

		foreach my $subdir ('_skins', 'upload/dav_rw', 'upload/dav_ro') {

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
	
	unless ($ELUDIA_BANNER_PRINTED) {

		print STDERR "\n";
		print STDERR " ----------------------------------------------------------------\n";
		print STDERR "\n";
		print STDERR " *****     *    ELUDIA / Perl                                    \n";
		print STDERR "     *    *                                                      \n";
		print STDERR "     *   *                                                       \n";
		print STDERR " ********       Version: $Eludia_VERSION [$Eludia::VERSION_NAME] \n";
		print STDERR "     * *                                                         \n";
		print STDERR "     **                                                          \n";
		print STDERR " *****          Copyright (c) 2002-2007 by Eludia                \n";
		print STDERR "\n";
		print STDERR " ----------------------------------------------------------------\n";

		our $ELUDIA_BANNER_PRINTED = 1;

	}

	print STDERR "\n   Loading $pkg_banner...";
	
	unless ($preconf -> {no_model_update}) {
		require DBIx::ModelUpdate;
	}

	if ($ENV {GATEWAY_INTERFACE} =~ m{^CGI/} || $conf -> {use_cgi} || $preconf -> {use_cgi}) {
		eval 'require CGI';
	} else {
		eval 'require Apache::Request';
		if ($@) {
			warn "$@\n";

			eval 'require CGI';
			eval 'require Eludia::Request';
		}
	}

	eval 'require Eludia::Request' unless ($INC {'Apache/Request.pm'});

#	our $STATIC_ROOT = __FILE__;
#	$STATIC_ROOT =~ s{\.pm}{/static/};

	eval 'require Compress::Zlib';
	if ($@) {
		delete $conf -> {core_gzip};
		delete $preconf -> {core_gzip};
	};

	our %INC_FRESH = ();	
	while (my ($name, $path) = each %INC) {
		delete $INC {$name} if $name =~ m{Eludia[\./]}; 
	}

	$conf = {%$conf, %$preconf};
	if ($conf -> {core_load_modules}) {
	
		foreach my $module (qw(Config Content::menu Content::logon Presentation::logon)) {
			require_fresh ($_PACKAGE . '::' . $module);
		}	
			
		if ($conf -> {auto_load}) {
			
			foreach my $type (@{$conf -> {auto_load}}) {				
				push @files, "${_PACKAGE}/Content/$type.pm";
				push @files, "${_PACKAGE}/Presentation/$type.pm";
			}
			
			eval {
				my $auto_load_expiry = $preconf -> {auto_load_expiry} || 5 * 24;
				sql_do ('DELETE FROM __required_files WHERE unix_ts < ?', time - $auto_load_expiry * 60 * 60);
				push @files, sql_select_col ('SELECT file_name FROM __required_files');
			};						
			
		}
		else {
		
			foreach my $path (reverse (@$PACKAGE_ROOT)) {

				opendir (DIR, "$path/Content") || die "can't opendir $PACKAGE_ROOT/Content: $!";
				push @files, grep {/\.pm$/} map { "${_PACKAGE}/Content/$_" } readdir (DIR);
				closedir DIR;	

				opendir (DIR, "$path/Presentation") || die "can't opendir $PACKAGE_ROOT/Presentation: $!";
				push @files, grep {/\.pm$/} map { "${_PACKAGE}/Presentation/$_" } readdir (DIR);
				closedir DIR;	

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

	if ($conf -> {db_dsn}) {
		eval {	sql_disconnect;	};
		warn $@ if $@;
	}

	print STDERR "\r   Loading $pkg_banner ok.\n\n";
}

1;

################################################################################

=head1 NAME

Eludia.pm - a RAD platform for WEB GUIs with rich DHTML widget set.

=head1 DESCRIPTION

Eludia.pm is a set of naming conventions, utility functions, and a basic Apache request handler that help to quickly build robust, efficient and good-looking Web interfaces with standard design. The last doesn't mean that you can't alter hardcoded HTML fragments at all. But building public Web sites with original graphics and layout is not the primary goal of Eludia development. Eludia is good for developing client database editing GUIs ('thin clients') and is conditionnally comparable to Windows API and java Swing.

Eludia' basic features are:

=over

=item GUI base

usable set of DHTML widgets (forms, toolbars, etc);

=item transparent DB scheme maintenace

when some table or field lacks, the application creates it silently;

=item ALC support

standard routines to backup, mirror and synchronize multiple installations of the same application (Eludia::Install);

=item sessions

session management subsystem with transparent query rewriting;

=item js alerting

server side error handling and data validation with client javaScript notifications without page reloading (yes, it really is);

=item logging

action logging is a part of core process, additionl API calls aren't needed;

=item fake records/garbage collection

handling of temporary records that are only visible on creation forms and wizards;

=back

=head1 DESIGN PRINCIPLES

There is a whole a lot of univesal web application platforms. So, why develop another one instead of using some mature product? 'Cause we've already tried many of this and have'nt found a good one. 

When developing Eludia, we use the following principles:

=over

=item no OO

HTTP is nothing else than evaluting string functions with sets of named parameters. Request handler must do nothing else than decompose the top function to some more primitive functions. So, Eludia is purely procedure-oriented framework.

=item content/presentation separation

Request handler reduce the top function f (x) to a superposition of a content and a presentation function: c (x) and p (c, x), where c (x) can't produce any HTML fragment in its result and p (c, x) can't use any info stored in the database.

	f (x) = p (c (x), x). 

=item URL discipline and strict callback naming

Content and presentation functions can be reduced to swithes between some elementary callback functions, where the switch is directly governed by known CGI parameters. Say, for C<url='/?type=users'> C<c == select_users> and C<p == draw_users>.

=item no ASP or like

Perl is ideal for implementing templating languages. That's why people love to implement new templating languages in Perl. But most of them ignore the fact that Perl I<is already> a templating language. Heredoc syntax is much more usable than any ASP-like. And it doesn't require any additional processing: everything is done by the Perl interpreter.

=item no XML

Nested Perl datastructures like list-of-hashes and more complex offer the same functionnality as the XML DOM model. And it doesn't require any external libraries: everything is done by the Perl interpreter.

=item no XSLT

It would be very strange to use XSLT without XML, but we must underline here that there was one more reason to not use XSLT. Its syntax is even much crappier and less flexible than ASP-like.

=back

=head1 MAGIC CGI PARAMETERS

The next CGI parameters have special meaning in Eludia URLs and can be used only as described.

=over

=item sid

Session ID. If not set, the client is automatically redirected to the logon screen.

=item type

Type of the current screen. Can have values like C<'users'> or, for example, C<'users_creation_wizard_step_2'>. Influences the callback functions selection and the main menu rendering.

=item id

Current object ID. Influences the callback functions selection. When set, the screen presents detailed info of one object, otherwise, it contains some search results.

=item action

Name of the action to execute. If set, the request handler executes some editing callback, then evalutes the new URL where C<action> is unset and redirects the client there.

=item salt

Fake random parameter for preventing the client HTML cacheing.

=back

=head1 GLOBAL VARIABLES

The next variables are accessible in all callback subs.

=over

=item %_REQUEST

The hash of CGI parameters and its values

=item $_USER

The hashref containing the current user information:
	
	{
		id   => ...
		name => ...
		role => ... 
	}

=back

=head1 CALLBACK SUBS

Under differnent circumstances, Eludia Apache request handler executes appropriate callback subs. The name of the callback to execute depends on current program context, C<type> value and the role of the current user. 

Suppose that the context imply the callback name C<$my_callback>, C<$_REQUEST{type}> is C<$type> and C<$$_USER {role}> is C<$role>. In this case, if the sub named "${my_callback}_${type}_for_${role}" is defined, it will be called. Otherwise, if the sub named "${my_callback}_${type}" is defined, it will be called. Otherwise, undef value will be used instead of missing sub result.

In the next sections, "${my_callback}_${type}_for_${role}" always means one of 3 cases described above.

=over

=item validate_{$action}_${type}_for_${role}

This sub must analyze the values of parameters in C<%_REQUEST> hash for consistency. In most cases, the object id is stored in C<$_REQUEST {id}> and the names of all other fields are underscore prefixed (C<$_REQUEST {_name}>, C<$_REQUEST {_login}>, C<$_REQUEST {_password}> etc). 

If everythig's OK, the validator must return C<undef>. Otherwise, the return value is an error code. We'll call it C<$error>. So, if C<$error> is defined, an error message template C<$$error_messages {"{$action}_${type}_${error}"}> is interpolated as a qq-string and then sent to the user as the error message.

For example, if the sub C<validate_update_users_for_admin> returns C<'duplicate_login'>, C<$_REQUEST {_login} eq 'scott'> and C<$$error_messages {"update_users_duplicate_login"} eq 'Duplicate login: \'$_REQUEST{_login}\''>, then the error message will be C<"Duplicate login: 'scott'">.

=item do_{$action}_${type}_for_${role}

This sub must execute the C<$action>. Note that you can choose the next screen shown to the user by manipulating the C<%_REQUEST> hash. For example, it's usual to set the C<id> parameter after creating new object:

	sub do_create_users_for_admin {
	
		sql_do ("INSERT INTO ... ");
		
		$_REQUEST {id} = sql_last_insert_id ();
	
	}

The client window will be rediredted to "/?type=users&id=1&sid=...".

=item get_item_of_${type}_for_${role}

This sub must fetch the info for the screen of type C<$type> having the obgect id C<$_REQUEST {id}> and the role C<${role}>. Usually it's a reference to a hash, may be nested.

=item select_${type}_for_${role}

This sub must fetch the info for the screen of type C<$type> and the role C<${role}>. Usually it's a reference to a list of references to hashes, may be nested.

=item draw_item_of_${type}_for_${role}

This sub must render the screen of type C<$type> having the obgect id C<$_REQUEST {id}> and the role C<${role}> as HTML. The info fetched with C<get_item_of_${type}_for_${role}> is passed as its 1st parameter.

=item draw_${type}_for_${role}

This sub must render the screen of type C<$type> sand the role C<${role}> as HTML. The info fetched with C<select_${type}_for_${role}> is passed as its 1st parameter.

=back

=head1 HTTP REQUEST HANDLING

=head2 SESSION CHECKING

First of all, the handler checks for the C<sid> param and, if the session is alive, it sets the C<$USER> variable, otherwise, redirects the client to the logon screen. 

=head2 EDITING REQUEST

If the C<action> CGI parameter is set, then the sub named C<validate_{$action}_${type}_for_${role}> is invoked. If if returns a non-empty error message, it's logged and presented with a js popup window. Otherwise the sub named C<do_{$action}_${type}_for_${role}> is invoked, then the client is redirected to the new URL composed from all C<%_REQUEST> key-value pairs except C<action> and those which names start with an C<'_'>.

In any case, the HTTP response has status 200 (OK) and contains a tiny HTML document consisting of a singular C<body> tag with a non-empty C<onLoad> event handler. When an error occurs, this handler displays the message in a js popup window. Otherwise the C<onLoad> handler opens the new URL in the top browser window.

Every conventional HTML page generated by Eludia Apache handler has a zero sized internal frame called C<invisible>. In order to improve the GUI usability, every anchor with non-empty C<action> parameter value in its href and every form with a non-empty value for C<action> input must use C<invisible> as the target:

	<a href="/type=folder&action=create" target="invisible">[New Folder]</a>
	
	<form action="/" target="invisible">
		...
	</form>
	


Standard Eludia HTML rendering API does this automatically.

=head2 OBJECT BROWSING REQUEST

If the C<action> CGI parameter is unset and C<id> CGI parameter is set, then the HTML resuls from the superposition of C<draw_item_of_${type}_for_${role}> and C<get_item_of_${type}_for_${role}> callbacks.

=head2 SELECTION BROWSING REQUEST

If both C<action> and C<id> CGI parameters are unset, then the HTML resuls from the superposition of C<draw_${type}_for_${role}> and C<select_${type}_for_${role}> callbacks.

=head1 MODULES STRUCTURE

Eludia modules don't have a C<package> directive. All the stuff is loaded in one package. 

Callback subs must be placed in strictly named .pm files. Suppose that you've chosen C<$applib> as your application library root and have placed it in your C<@INC> array. Then, create C<$applib/Content> and C<$applib/Presentation> directories. 

Now, all content callbacks (C<validate_{$action}_${type}_for_${role}>, C<do_{$action}_${type}_for_${role}>, C<get_item_of_${type}_for_${role}> and C<select_${type}_for_${role}>) must be defined in C<$applib/Content/${type}.pm> and presentation callbacks (C<draw_item_of_${type}_for_${role}> and C<draw_${type}_for_${role}>) in C<$applib/Presentation/${type}.pm>.

	$applib
		Content
			roles.pm
			users.pm
		Presentation
			roles.pm
			users.pm
			
=head1 MORE API DOCS

Generate it:

	perl -MEludia::Docs -e generate

=head1 SEE ALSO

DBIx::ModelUpdate Eludia::Install

=head1 AUTHORS

Dmitry Ovsyanko <do@eludia.ru>
Pavel Kudryavtzev <pashka@eludia.ru>
Yaroslav Ivanov <... hekima ...>

1;