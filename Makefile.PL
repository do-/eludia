use ExtUtils::MakeMaker;

'$LastChangedDate: 2008-03-04 12:34:56 +0300 (¬т, 04 мар 2008) $' =~ /(\d\d)(\d\d)\-(\d\d)\-(\d\d)/;
	
my $VERSION  = "$2.$3.$4";

'$LastChangedRevision: 1086 $' =~ /(\d+)/;
	
$VERSION .= ".$1";

my $VERSION = '';

open S, 'Eludia.pm';

while (<S>) {
	if (/LastChangedDate\: (\d\d)(\d\d)-(\d\d)-(\d\d)/) {$VERSION = "$2.$3.$4"}
	if (/LastChangedRevision\: (\d+)/)                  {$VERSION .= ".$1"}
}

close S;

WriteMakefile(
    'NAME'		=> 'Eludia',
    'VERSION'	        => $VERSION,
    'PREREQ_PM'		=> {
	'Net::SMTP'		=> '',
	'Apache'		=> '',
	'DBI'			=> '1.21',
	'Number::Format'	=> '1.45',
	'Storable'		=> '',
	'MIME::Base64'		=> '',
	'Time::HiRes'		=> '',
	'File::Temp'		=> '',
	'Digest::MD5'		=> '',
	'Fcntl'			=> '',
	'XML::Simple'		=> '2.14',
	'JSON::XS'		=> '1.43',
#	'Math::FixedPrecision'  => '',
    },
    ($] >= 5.005 ?    
	(
	ABSTRACT   => 'A RAD platform for WEB GUIs with rich DHTML widget set.', 
	AUTHOR     => 'D. Ovsyanko') : ())
);
