require JSON;

my $fn = 'conf/elud.json';
open (I, $fn) or die "Can't read $fn: $!";
my $json = join '', grep /^[^\#]/, (<I>);
close (I);

our $preconf = JSON::decode_json ($json);