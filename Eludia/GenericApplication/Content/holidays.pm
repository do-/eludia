################################################################################

sub do_switch_holidays {

	my $is_holiday = sql_select_scalar ('SELECT id FROM holidays WHERE dt = ? AND fake = 0', $_REQUEST {dt}) ? 1 : 0;

	sql_do (
			
		($is_holiday ?
			
			"DELETE FROM $conf->{systables}->{holidays} WHERE dt = ?" :
				
			"INSERT INTO $conf->{systables}->{holidays} (fake, dt) VALUES (0, ?)"
				
		),
					
		$_REQUEST {dt}
			
	);
	
	out_html ({}, qq {
	
		<html>
			<head>			
				<script>

					parent.\$('#day_$_REQUEST{dt}').css ({backgroundColor: parent.color [1 - $is_holiday]});

				</script>
			</head>
		</html>
	
	});
		
	$_REQUEST {__response_sent} = 1;

}

################################################################################

sub select_holidays {

	my ($y, $m, $d) = Today ();

	my $data = {years => [map {{id => $_, label => $_}} (2010 .. $y + 1)]};

	$_REQUEST {year} ||= $y;

	sql ($conf -> {systables} -> {holidays} => [['dt BETWEEN ? AND ?' => ["$_REQUEST{year}-01-01", "$_REQUEST{year}-12-31"]]], sub {

		$data -> {holidays} -> {dt_iso ($i -> {dt})} = 1;

	});

	if (!%{$data -> {holidays}}) {

		my ($year, $month, $day) = ($_REQUEST {year}, 1, 1);
	
		my @dts = ();
	
		my $dow = Day_of_Week ($year, $month, $day);
	
		while ($year == $_REQUEST {year}) {
	
			$data -> {holidays} -> {dt_iso ($year, $month, $day)} = 1 if ($dow > 5);
	
			($year, $month, $day) = Add_Delta_Days ($year, $month, $day, 1);
	
			$dow ++;
	
			$dow = 1 if $dow == 8;
		
		}
	
		my $st = $db -> prepare ("INSERT INTO $conf->{systables}->{holidays} (fake, dt) VALUES (0, ?)");
	
		$st -> execute_array ({}, [keys %{$data -> {holidays}}]);
	
		$st -> finish;
	
	}

	return $data;

}

1;
