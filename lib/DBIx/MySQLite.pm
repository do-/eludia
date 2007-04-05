package DBIx::MySQLite;

use 5.006;
use strict;
use warnings;

use POSIX qw (strftime);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	add_all_functions
	add_string_functions
	add_datetime_functions
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.1';

################################################################################

sub format_datetime {
	$_[0] =~ s{\%i}{\%M};
	return POSIX::strftime (@_);
}

################################################################################

sub parse_datetime {
	my ($s) = @_;	
	$s =~ s{[^\d]}{}g;	
	$s =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;	
	return ($6, $5, $4 , $3, $2 - 1, $1 - 1900);
}


################################################################################

sub add_all_functions {
	add_string_functions   (@_);
	add_datetime_functions (@_);
};

################################################################################

sub add_string_functions {

	my $db = shift;
	
	$db -> func ('REPLACE', 3, sub { 
		my ($s, $from, $to) = @_;
		$s =~ s{$from}{$to}g;
		return $s;
	}, 'create_function');
	
	
};

################################################################################

sub add_datetime_functions {

	my $db = shift;
	
	$db -> func ('NOW', 0, sub { 
		return POSIX::strftime ('%Y-%m-%d %H:%M:%S', localtime (time));
	}, 'create_function');	
	
	$db -> func ('DATE_FORMAT', 2, sub { 
		return format_datetime ($_[1], parse_datetime ($_[0]));
	}, 'create_function');	

};

################################################################################

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DBIx::MySQLite - MySQL compatibility functions for DBD::SQLite.

=head1 SYNOPSIS

  use DBI;
  use DBIx::MySQLite 'add_all_functions';
  
  my $db = DBI -> connect ("dbi:SQLite:dbname=sql.ite","","", {RaiseError => 1});  
  
  DBIx::MySQLite::add_string_functions   ($db);
  DBIx::MySQLite::add_datetime_functions ($db);
  
  # or simply
  
  add_all_functions ($db);
  
  $db -> do ('UPDATE syslog SET dt = REPLACE(NOW(), '200', '175'...

=head1 ABSTRACT

  MySQL compatibility functions for DBD::SQLite.
  

=head1 DESCRIPTION

DBD::SQLite is a set of callback function definitions making it look more or less like MySQL. As of version 0.1, just a very basic set is available, patches are very welcome.

=over

=item NOW()

Current timestamp, in format 'YYYY-MM-DD hh:mm:ss'.

=item DATE_FORMAT()

Only %Y, %m, %d, %H, %i and %S patterns are guaranteed, other may work (see POSIX::strftime).

=item REPLACE()

=back


=head1 SEE ALSO

DBD::SQLite.

=head1 AUTHOR

D. E. Ovsyanko, E<lt>do@eludia.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by D. E. Ovsyanko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
