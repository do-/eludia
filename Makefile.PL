use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Eludia',
    'VERSION_FROM'	=> 'Eludia.pm',
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
