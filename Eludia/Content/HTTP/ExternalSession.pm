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

sub download {

	my ($self, $params, $options) = @_;

	my ($path, $real_path) = &{"$self->{package}::upload_path"} ('foo.bar', $options);
	
	$self -> query ($params, $real_path);
	
	return $self -> {error} if $self -> {error};
	
	my $disposition = $self -> {response} -> header ('Content-Disposition');

	$disposition =~ /filename=(.*?)(\w+)$/ or return $self -> {error} = "Bad 'Content-Disposition' header: '$disposition'";

	my ($name, $ext) = ($1, $2);

	my $old_real_path = $real_path;

	$real_path =~ s{bar$}{$ext};

	$path      =~ s{bar$}{$ext};

	rename $old_real_path, $real_path;

	$self -> {file} = {

		file_name => $name . $ext,

		size      => -s $real_path,

		type      => $self -> {response} -> header ('Content-Type'),

		path      => $path,

		real_path => $real_path,

	};

	undef;

}

sub query {

	my ($self, $params, $destination) = @_;
	
	delete $self -> {$_} foreach qw (url url_params error content response file);

	$params -> {sid} = $self -> {sid} if $self -> {sid};
	
	my $request = HTTP::Request::Common::POST ($self -> {host}, $params, 'Content_Type' => 'form-data');
	
	$self -> {response} = $self -> {ua} -> request ($request, $destination);
	
	$self -> {response} -> is_error and return $self -> {error} = $self -> {response} -> message;
	
	if (my $json = $self -> {response} -> content) {

		my $h = $self -> {json} -> decode ($json);

		$h -> {message} and return $self -> {error} = $h -> {message};

		$self -> {$_} = $h -> {$_} foreach qw (url content);

		if ($self -> {url} =~ /\?/) {

			foreach (split /\&/, $') {

				my ($k, $v) = split /\=/;

				$self -> {url_params} -> {$k} = $v;

			}

		}
	
	}

	undef;

}

1;