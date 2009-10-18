package Eludia::Content::HTTP::ExternalSession;

require HTTP::Request::Common;

sub login {

	my ($self, $params) = @_;
	
	$params -> {type}   ||= 'logon';
	
	$params -> {action} ||= 'execute';

	$self -> query ($params) and return $self -> {error};
	
	($self -> {sid} = $self -> {url_params} -> {sid}) or return ($self -> {error} = 'Îøèáêà àâòîğèçàöèè');
	
	undef;

}

sub query {

	my ($self, $params) = @_;
	
	delete $self -> {$_} foreach qw (url url_params error content);

	$params -> {sid} = $self -> {sid} if $self -> {sid};
	
	my $request = HTTP::Request::Common::POST ($self -> {host}, $params, 'Content_Type' => 'form-data');
	
	my $response = $self -> {ua} -> request ($request);
	
	$response -> is_error and return $self -> {error} = $response -> message;

	my $h = $self -> {json} -> decode ($response -> content);
	
	$h -> {message} and return $self -> {error} = $h -> {message};
	
	$self -> {$_} = $h -> {$_} foreach qw (url content);
	
	if ($self -> {url} =~ /\?/) {
		
		foreach (split /\&/, $') {
		
			my ($k, $v) = split /\=/;
		
			$self -> {url_params} -> {$k} = $v;
		
		}
	
	}
	
	undef;

}

1;