
################################################################################

sub session_access_logs_purge {
	
	my $ids = sql_select_ids ("SELECT id FROM $conf->{systables}->{sessions}");
	
	sql_do ("DELETE FROM $conf->{systables}->{__access_log} WHERE id_session NOT IN ($ids)");
	
}

################################################################################

sub session_access_log_get {
	
	sql_select_scalar ("SELECT href FROM $conf->{systables}->{__access_log} WHERE id_session = ? AND no = ?", $_REQUEST {sid}, $_ [0]);
	
}

################################################################################

sub session_access_log_append {

	my ($href) = @_;
	
	my $no = 1 + sql_select_scalar ("SELECT MAX(no) FROM $conf->{systables}->{__access_log} WHERE id_session = ?", $_REQUEST {sid});
	
	sql_do ("INSERT INTO $conf->{systables}->{__access_log} (id_session, no, href) VALUES (?, ?, ?)", $_REQUEST {sid}, $no, $href);

	return $no;

}

################################################################################

sub session_access_log_set {

	my ($href) = @_;

	$href =~ s{^https?\://}{};
	
	if ($href =~ /[\/\?]/) {
		
		$href = $& . $';
	
	}
		
	foreach my $key (qw(
		_salt
		salt
		sid
		id___query
		__next_query_string
	)) {
	
		$href =~ s{\&?${key}=[\d\.]+}{}g;
	
	}
	
	my $no = sql_select_scalar ("SELECT no FROM $conf->{systables}->{__access_log} WHERE id_session = ? AND href = ?", $_REQUEST {sid}, $href);
		
	return $no ? $no : session_access_log_append ($href);

}

1;