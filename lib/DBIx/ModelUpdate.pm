package DBIx::ModelUpdate;

use 5.005;

require Exporter;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use DBI::Const::GetInfoType;

use Storable    ('freeze', 'dclone');
use Digest::MD5 'md5_base64';
use Time::HiRes 'time';

no strict;
no warnings;

################################################################################

sub canonic_key_definition {

	my ($self, $s) = @_;
	
	$s =~ s{\s+}{}g;
	
	return $s;

}

################################################################################

sub __log_profilinig {

	printf STDERR "Profiling [$$] %20.10f ms %s\n", 1000 * (time - $_[0]), $_[1];
	
	return time ();

}

################################################################################

sub do {

	my ($self, $sql) = @_;
	print STDERR $sql, "\n" if $self -> {dump_to_stderr};	
	$self -> {db} -> do ($sql);

}

################################################################################

sub new {

	my ($package_name, $db, @options) = @_;
	
	my $driver_name = $db -> get_info ($GetInfoType {SQL_DBMS_NAME});
	
	$driver_name =~ s{\s}{}gsm;
		
	$package_name .= "::$driver_name";

	eval "require $package_name";
	
	die $@ if $@;

	my $self = bless ({
		db => $db, 
		checksums => 1, 
		driver_name => $driver_name,
		quote => $db -> get_info ($GetInfoType {SQL_IDENTIFIER_QUOTE_CHAR}),
		@options
	}, $package_name);
	
	if ($driver_name eq 'SQLite') {
		require DBIx::MySQLite;
		DBIx::MySQLite::add_all_functions ($db);
	}

	if ($driver_name eq 'Oracle') {
  		$self -> {characterset} = $self -> sql_select_scalar ('SELECT VALUE FROM V$NLS_PARAMETERS WHERE PARAMETER = ?', 'NLS_CHARACTERSET');
  		$self -> {schema} ||= uc $db -> {Username};
  		$self -> {__voc_replacements} = "$self->{quote}$self->{__voc_replacements}$self->{quote}" if $self -> {__voc_replacements} =~ /^_/;
	}
	
	if ($driver_name eq 'PostgreSQL') {
		$self -> {schema} = $self -> sql_select_scalar ('SELECT current_schema()');
	}
	
	$self -> {schema} ||= '';

	return $self;

}

################################################################################

sub checksum {
	return md5_base64 (freeze ($_[0]));	
}

################################################################################

sub assert {

my $time = time;

	my ($self, %params) = @_;
	
	$Storable::canonical = 1;
	
	my $checksum = '';
	my $_db_model_checksums = 
		$self -> {_db_model_checksums}     ? $self -> {_db_model_checksums} : 
		$self -> {driver_name} eq 'Oracle' ? '"_db_model_checksums"' 
		: '_db_model_checksums';

	unless ($params {no_checksums}) {

		$checksum = checksum (\%params);

		return if exists $self -> {checksums} -> {$checksum};
				
		eval {
			my $st = $self -> {db} -> prepare ("SELECT COUNT(*) FROM $_db_model_checksums WHERE checksum = ?");
			$st -> execute ($checksum);
			($self -> {checksums} -> {$checksum}) = $st -> fetchrow_array;
			$st -> finish;
		};
		
		return if $self -> {checksums} -> {$checksum};
		
		if ($@) {
		
			my $index_name = $_db_model_checksums;
			$index_name =~ s{(\w+)}{$1_pk};
		
			$self -> do ("CREATE TABLE $_db_model_checksums (checksum CHAR(22))");
			$self -> do ("CREATE INDEX $index_name ON $_db_model_checksums (checksum)");
		
my $time = __log_profilinig ($time, '   checksum table created');

		}

	}	

	my $existing_tables = {};	
	
	foreach my $table ($self -> {db} -> tables ('', $self -> {schema}, '%', "'TABLE'")) {
	
		$existing_tables -> {$self -> unquote_table_name ($table)} = {};

	}

my $time = __log_profilinig ($time, '   got existing_tables ');

	&{$self -> {before_assert}} (@_) if ref $self -> {before_assert} eq CODE;		
	
	my $needed_tables = $params {tables};
		
	my $checksums2names = {};
	my $checksums = "''";

	foreach my $name (keys %$needed_tables) {

		my $definition = $needed_tables -> {$name};
		$definition -> {$name} = $name;

		foreach my $dc_name (keys %{$params {default_columns}}) {

			my $dc_definition = $params {default_columns} -> {$dc_name};
			$definition -> {columns} -> {$dc_name} ||= dclone ($dc_definition);
			
		};
		
		next if $params {no_checksums};

		my $checksum = checksum ($definition);

		$checksums .= ",'$checksum'";

		$checksums2names -> {$checksum} = $name;

		my $st = $self -> {db} -> prepare ("SELECT checksum FROM $_db_model_checksums WHERE checksum IN ($checksums)");
		$st -> execute ();
		while (my ($existing_checksum) = $st -> fetchrow_array) {
			delete $needed_tables -> {$checksums2names -> {$existing_checksum}};
		}
		
		$st -> finish;
	
	};

my $time = __log_profilinig ($time, '   needed_tables filtered');
		
	foreach my $name (keys %$needed_tables) {
		exists $existing_tables -> {$name} or next;
		$existing_tables -> {$name} -> {columns} = $self -> get_columns ($name); 
		$existing_tables -> {$name} -> {keys}    = $self -> get_keys    ($name, $params {core_voc_replacement_use}); 
	} 

my $time = __log_profilinig ($time, '   got keys & columns');
	
	foreach my $name (keys %$needed_tables) {
	
		my $definition = $needed_tables -> {$name};
	
		my $checksum = checksum ($definition);

		if ($existing_tables -> {$name}) {
		
			my $existing_columns = $existing_tables -> {$name} -> {columns};
			
			my $new_columns = {};
				
			foreach my $c_name (keys %{$definition -> {columns}}) {
			
				my $c_definition = $definition -> {columns} -> {$c_name};

				if ($existing_columns -> {$c_name}) {
				
					my $existing_column = $existing_columns -> {$c_name};										

					my $flag = $self -> update_column ($name, $c_name, $existing_column, $c_definition,,$params {core_voc_replacement_use});

my $time = __log_profilinig ($time, "    $name.$c_name " . ($flag ? 'updated' : 'checked'));

				}
				else {
				
					$new_columns -> {$c_name} = $c_definition;
				
				}

			};
			
			if (keys %$new_columns) {

				$self -> add_columns ($name, $new_columns,,$params {core_voc_replacement_use});

my $time = __log_profilinig ($time, "    columns added");

			}

			foreach my $k_name (keys %{$definition -> {keys}}) {
			
				my $k_definition = $self -> canonic_key_definition ($definition -> {keys} -> {$k_name});
						
				if ($existing_tables -> {$name}) {
					
					my $existing_definition = $self -> canonic_key_definition ($existing_tables -> {$name} -> {keys} -> {$k_name});
					
					if ($existing_definition) {
										
						next if $existing_definition eq $k_definition;

						$self -> drop_index ($name, $k_name, $params {core_voc_replacement_use});

my $time = __log_profilinig ($time, "    key $name.$k_name dropped because '$existing_definition' ne '$k_definition'");

					}
				
				}						
				
				$self -> create_index ($name, $k_name, $k_definition, $definition, $params {core_voc_replacement_use});

my $time = __log_profilinig ($time, "    key $name.$k_name created");

			};

		}
		else {
		

			$self -> create_table ($name, $definition, $params {core_voc_replacement_use});
		
			foreach my $k_name (keys %{$definition -> {keys}}) {
			
				my $k_definition = $definition -> {keys} -> {$k_name};
				
				$k_definition =~ s{\s+}{}g;
				
				$self -> create_index ($name, $k_name, $k_definition, $definition, $params {core_voc_replacement_use});

			};

		}

		map { $self -> insert_or_update ($name, $_, $definition) } @{$definition -> {data}} if $definition -> {data};
		
		unless ($params {no_checksums}) {
			$self -> do ("INSERT INTO $_db_model_checksums (checksum) VALUES ('$checksum')") unless $params {no_checksums};
		}

	}

	unless ($params {no_checksums}) {
		$self -> do ("INSERT INTO $_db_model_checksums (checksum) VALUES ('$checksum')");
		$self -> {checksums} -> {$checksum} = 1;	
	}

}

################################################################################


1;
__END__

=head1 NAME

DBIx::ModelUpdate - tool for check/update database schema

=head1 SYNOPSIS

	use DBIx::ModelUpdate;

	### Initialize

	my $dbh = DBI -> connect ($connection_string, $user, $password);    	
	my $update = DBIx::ModelUpdate -> new ($dbh);

	### Ensure that there exists the users table with the admin record
  
	$update -> assert (
  
		tables => {		
		
			users => {
				
				columns => {

					id => {
						TYPE_NAME  => 'int',
						_EXTRA => 'auto_increment',
						_PK    => 1,
					},

					name => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 50,
						COLUMN_DEF   => 'New user',
						NULLABLE     => 0,
					},

					password => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 255,
					},

				},
				
				data => [
				
					{id => 1, name => 'admin', password => 'bAckd00r'},
				
				],
			
			},

		},
  
	); 

	### Querying the structure
	
	my $schema        = $update -> get_tables;
	my $users_columns = $update -> get_columns ('users');	
	

=head1 ABSTRACT

  This module let your application ensure the necessary database structure without much worrying about its current state.

=head1 DESCRIPTION

When maintaining C<mod_perl> Web applications, I often find myself in a little trouble. Suppose there exist:
 - a production server with an old version of my application and lots of actual data in its database;
 - a development server with a brand new version of Perl modules and a few outdated info in its database. 
 
Now I want to upgrade my application so that it will work properly with actual data. In most simple cases all I need is to issue some Ñ<CREATE TABLE/ALTER TABLE> statements in SQL console. In some more complicated cases I write (by hand) a simple SQL script and then run it. Some tool like C<mysqldiff> may help me.

Consider the situation when there are some different Web applications with independent databases sharing some common modules that use DBI and explicitly rely on the database(s) structure. All of these are installed on different servers. What shoud I do after introducing some new features in this common modules? The standard way is to dump the structure of each database, write and test a special SQL script, then run it on the appropriate DB server and then update the code. But I prefer to let my application do it for me.

When starting, my application must ensure that:
 - there are such and such tables in my base (there can be much others, no matter);
 - a given table contain such and such columns (it can be a bit larger thugh, it's ok);
 - dictionnary tables are filled properly.

If eveything is OK the application starts immediately, otherwise it slightly alters the schema and then runs as usual.

=head2 ONE TABLE

For example, if I need a C<users> table with standard C<id>, C<name> and C<password> columns in it, I write

	$update -> assert (
  
		tables => {		
		
			users => {
				
				columns => {

					id => {
						TYPE_NAME  => 'int',
						_EXTRA => 'auto_increment',
						_PK    => 1,
					},

					name => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 50,
						COLUMN_DEF   => 'New user',
					},

					password => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 255,
					},

				},
							
			},

		},
  
	); 

=head2 MANY TABLES

Consider a bit more complex schema consisting of two related tables: C<users> and C<sex>:

	$update -> assert (
  
		tables => {		
		
			users => {
				
				columns => {

					id => {
						TYPE_NAME  => 'int',
						_EXTRA => 'auto_increment',
						_PK    => 1,
					},

					name => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 50,
						COLUMN_DEF   => 'New user',
					},

					password => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 255,
					},

					id_sex => {
						TYPE_NAME  => 'int',
					},

				},
							
			},

			sex => {
				
				columns => {

					id => {
						TYPE_NAME  => 'int',
						_EXTRA => 'auto_increment',
						_PK    => 1,
					},

					name => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 1,
					},

				},
							
			},

		},
  
	); 
	
=head2 MANY TABLES WITH SIMLAR COLUMNS	

It's very clear that each entity table in my schema has the same C<id> field, so I will declare it only once:

	$update -> assert (
	
		default_columns => {

			id => {
				TYPE_NAME  => 'int',
				_EXTRA => 'auto_increment',
				_PK    => 1,
			},

		},	
  
		tables => {		
		
			users => {
				
				columns => {

					name => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 50,
						COLUMN_DEF   => 'New user',
					},

					password => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 255,
					},

					id_sex => {
						TYPE_NAME  => 'int',
					},

				},
							
			},

			sex => {
				
				columns => {

					name => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 1,
					},

				},
							
			},

		},
  
	); 

=head2 INDEXING

The next example shows how to index your tables:

	$update -> assert (
	
		default_columns => {

			id => {
				TYPE_NAME  => 'int',
				_EXTRA => 'auto_increment',
				_PK    => 1,
			},

		},	
  
		tables => {		
		
			users => {
				
				columns => {

					name => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 50,
						COLUMN_DEF   => 'New user',
					},

					password => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 255,
					},

					id_sex => {
						TYPE_NAME  => 'int',
					},

				},
				
				keys => {
				
					fk_id_sex => 'id_sex'
				
				}
							
			},

			sex => {
				
				columns => {

					name => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 1,
					},

				},
							
			},

		},
  
	); 

=head2 DICTIONNARY DATA

Finally, I want ensure that each sex is enumerated and named properly:

	$update -> assert (
	
		default_columns => {

			id => {
				TYPE_NAME  => 'int',
				_EXTRA => 'auto_increment',
				_PK    => 1,
			},

		},	
  
		tables => {		
		
			users => {
				
				columns => {

					name => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 50,
						COLUMN_DEF   => 'New user',
					},

					password => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 255,
					},

					id_sex => {
						TYPE_NAME  => 'int',
					},

				},
							
			},

			sex => {
				
				columns => {

					name => {
						TYPE_NAME    => 'varchar',
						COLUMN_SIZE  => 1,
					},

				},
				
				data => [
				
					{id => 1, name => 'M'},
					{id => 2, name => 'F'},
				
				]
							
			},

		},
  
	); 

That's all. Now if I want to get back the structure of my database I write

	my $schema        = $update -> get_tables;
	
or 

	my $users_columns = $update -> get_columns ('users');	
	
for single table structure.

=head1 COMPATIBILITY

As of this version, only MySQL >= 3.23.xx is supported. It's quite easy to clone C<DBIx::ModelUpdate::mysql> and adopt it for your favorite DBMS. Volunteers are welcome.

=head1 SECURITY ISSUES

It will be good idea to create C<DBIx::ModelUpdate> with another C<$dbh> than the rest of your application. C<DBIx::ModelUpdate> requires administrative privileges while regular user souldn't.

And, of course, consider another admin password than C<bAckd00r> :-)

=head1 SEE ALSO

mysqldiff

=head1 AUTHOR

D. E. Ovsyanko, E<lt>do@eludia.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by D. E. Ovsyanko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
