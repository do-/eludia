use Test::More tests => 1;

my $table = 'testtesttesttable1';

sub cleanup {

	eval {sql_do ("DROP TABLE $table")};

}

cleanup ();

sql_do ("CREATE TABLE $table (a CHAR (3))");
sql_do ("INSERT INTO  $table (a) VALUES (?)", 'AAA');

is (sql_select_scalar ("SELECT a FROM $table"), 'AAA', 'SELECT 1');

END  { cleanup (); }