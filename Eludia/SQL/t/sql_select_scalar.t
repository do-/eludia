use Test::More tests => 1;

is (sql_select_scalar ('SELECT 1'), 1, 'SELECT 1');
