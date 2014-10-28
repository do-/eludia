
################################################################################

sub vld_snils {

	my ($name, $nullable) = @_;

	my $name1;
	my $value;
	if ($name !~ /^[\-\d ]$/) {
		$name1 = '_' . $name;
		$value = $_REQUEST {$name1};
	} else {
		$value = $name;
	}

	if (!$value && $nullable) {
		delete $_REQUEST {$name1} if ($name1);
		return undef;
	}

	local $SIG {__DIE__} = 'DEFAULT';

	$value =~ s/[^\d]//g;

	substr ($value, 0, 9) gt '001001998' or return undef;

	$value =~ /^\d{11}$/ or $name1 ? die "#$name1#:СНИЛС должен состоять из 11 арабских цифр" : return 'Код ИНН должен состоять из 11 арабских цифр';

	my @n = split //, $value;

	my $checksum =
		$n [0] * 9  +
		$n [1] * 8  +
		$n [2] * 7 +
		$n [3] * 6  +
		$n [4] * 5  +
		$n [5] * 4  +
		$n [6] * 3  +
		$n [7] * 2  +
		$n [8] * 1;

	$checksum = $checksum % 101;

	$checksum == 0 + substr ($value, 9, 2) or $name1 ? die "#$name1#:Не сходится контрольная сумма СНИЛС" : return 'Не сходится контрольная сумма СНИЛС';

	$_REQUEST {$name1} = substr ($value, 0, 3)
		. '-' . substr ($value, 3, 3)
		. '-' . substr ($value, 6, 3)
		. ' ' . substr ($value, 9, 2) if ($name1);

	return undef;

}

################################################################################

sub vld_date {

	my ($name, $nullable) = @_;
	
	$name = "_" . $name;
	
	if (!$_REQUEST {$name} && $nullable) {
		$_REQUEST {$name} = undef;
		return undef;
	}
	
	my ($_sec, $_min, $_hour, $_mday, $_mon, $_year, $_wday, $_yday, $_isdst) = localtime (time);

	$_REQUEST {$name} =~ s{^(\d\d\d\d)-(\d\d)-(\d\d)$}{$3.$2.$1};

	my ($day, $month, $year) = split /\D+/, $_REQUEST {$name};
	
	local $SIG {__DIE__} = 'DEFAULT';

	if (!$year) {
		$year = $_year + 1900;
	}
	elsif ($year < 100) {
		my $now_year = $_year + 1900;
		$now_year =~ /(\d\d)(\d\d)/;
		my $now_year_100 = $now_year % 100;
		my $century = $now_year - $now_year_100;
		$century -= 100 if ($year > $now_year + 10);
		$year += $century;
	}	
	elsif ($year < 1000) {
		die "#${name}#:Некорректно задан год\n";
	}
	

	$month > 0  or die "#${name}#:$$i18n{wrong_month}\n";
	$month < 13 or die "#${name}#:$$i18n{wrong_month}\n";
	
	$day   > 0  or die "#${name}#:$$i18n{wrong_day}\n";
	$day   < 32 or die "#${name}#:$$i18n{wrong_day}\n";
	
	Date::Calc::check_date ($year, $month, $day) or die "#${name}#:Некорректная дата\n";

	$_REQUEST {$name} = sprintf ('%04d-%02d-%02d', $year, $month, $day);
		
	return ($year, $month, $day);

}

################################################################################

sub vld_unique {

	my ($table, $options) = @_;
	
	$options -> {field} ||= 'label';
	$options -> {value} ||= $_REQUEST {'_' . $options -> {field}};
	$options -> {id}    ||= $_REQUEST {id};
	
	my $filter = "$$options{field} = ? AND fake = 0 AND id <> ?";
	$filter .= " AND $$options{filter}" if $options -> {filter};
	
	my $id = sql_select_scalar ("SELECT id FROM $table WHERE $filter LIMIT 1", $options -> {value}, $options -> {id});

	return $id ? 0 : 1;

}

################################################################################

sub vld_noref {

	my ($table, $options) = @_;
	
	$options -> {data_field} ||= 'label';
	
	unless ($options -> {field}) {
		$options -> {field} = 'id_' . $_REQUEST {type};
		$options -> {field} =~ s{s$}{};
	}
	
	$options -> {id} ||= $_REQUEST {id};
	
	$options -> {message} ||= 'На данную запись ссылается "$label". Удаление невозможно.';
	
	my $label = sql_select_scalar ("SELECT $$options{data_field} FROM $table WHERE $$options{field} = ? AND fake = 0 LIMIT 1", $options -> {id});
	
	return undef unless $label;
	
	my $message = $options -> {message};
	$message    =~ s{\$label}{$label};
	$message    .= "\n";
	
	local $SIG {__DIE__} = 'DEFAULT';
	
	die $message;

}

################################################################################

sub vld_inn_10 {

	my ($name, $nullable) = @_;
	
	my $name1;
	my $value;
	if ($name =~ /\D/) {
		$name1 = '_' . $name;
		$value = $_REQUEST {$name1};
	} else {
		$value = $name;
	} 

	if (!$value && $nullable) {
		delete $_REQUEST {$name1} if ($name1);
		return undef;
	}
	
	local $SIG {__DIE__} = 'DEFAULT';

	$value =~ /^\d{10}$/ or $name1 ? die "#$name1#:Код ИНН должен состоять из 10 арабских цифр" : return 'Код ИНН должен состоять из 10 арабских цифр';

	my @n = split //, $value;
		
	my $checksum =
		$n [0] * 2  +
		$n [1] * 4  +
		$n [2] * 10 +
		$n [3] * 3  +
		$n [4] * 5  +
		$n [5] * 9  +
		$n [6] * 4  +
		$n [7] * 6  +
		$n [8] * 8;
			
	$checksum = $checksum % 11;		
	$checksum = $checksum % 10 if $checksum > 9;
		
	$checksum == 0 + substr ($value, -1, 1) or $name1 ? die "#$name1#:Не сходится контрольная сумма ИНН" : return 'Не сходится контрольная сумма ИНН';

	return undef;

}

################################################################################

sub vld_inn_12 {

	my ($name, $nullable) = @_;
	
	my $name1;
	my $value;
	if ($name =~ /\D/) {
		$name1 = '_' . $name;
		$value = $_REQUEST {$name1};
	} else {
		$value = $name;
	} 

	if (!$value && $nullable) {
		delete $_REQUEST {$name1} if ($name1);
		return undef;
	}
	
	local $SIG {__DIE__} = 'DEFAULT';

	$value =~ /^\d{12}$/ or $name1 ? die "#$name1#:Код ИНН должен состоять из 12 арабских цифр" : return 'Код ИНН должен состоять из 12 арабских цифр';
	
	my @n = split //, $value;
		
	my $checksum =
		$n [0]  * 7  +
		$n [1]  * 2  +
		$n [2]  * 4  +
		$n [3]  * 10 +
		$n [4]  * 3  +
		$n [5]  * 5  +
		$n [6]  * 9  +
		$n [7]  * 4  +
		$n [8]  * 6  +
		$n [9]  * 8  +
		0;
				
	$checksum = $checksum % 11;
	$checksum = 0 if $checksum > 9;
			
	$checksum == 0 + substr ($value, -2, 1) or $name1 ? die "#$name1#:Не сходится первая контрольная сумма ИНН" : return 'Не сходится первая контрольная сумма ИНН';
		
	$checksum =
		$n [0]  * 3  +
		$n [1]  * 7  +
		$n [2]  * 2  +
		$n [3]  * 4  +
		$n [4]  * 10 +
		$n [5]  * 3  +
		$n [6]  * 5  +
		$n [7]  * 9  +
		$n [8]  * 4  +
		$n [9]  * 6  +
		$n [10] * 8  +
		0;
				
	$checksum = $checksum % 11;
	$checksum = 0 if $checksum > 9;
			
	$checksum == 0 + substr ($value, -1, 1) or $name1 ? die "#$name1#:Не сходится вторая контрольная сумма ИНН" : return 'Не сходится вторая контрольная сумма ИНН';

	return undef;

}

################################################################################

sub vld_inn {

	my ($name, $nullable) = @_;

	my $name1;
	my $value;
	if ($name =~ /\D/) {
		$name1 = '_' . $name;
		$value = $_REQUEST {$name1};
	} else {
		$value = $name;
	} 

	if (!$value && $nullable) {
		delete $_REQUEST {$name1} if ($name1);
		return undef;
	}

    if (length $value == 10) {
		return vld_inn_10 ($name);
	} elsif (length $value == 12) {
		return vld_inn_12 ($name);
	} else {
		return $name1 ? die "#$name1#:ИНН должен состоять либо из 10, либо из 12 цифр" : return 'ИНН должен состоять либо из 10, либо из 12 цифр';
	}

}

################################################################################

sub vld_okpo {

	my ($name, $nullable) = @_;
	
	$name = "_" . $name;
	
	if (!$_REQUEST {$name} && $nullable) {
		delete $_REQUEST {$name};
		return undef;
	}
	
	local $SIG {__DIE__} = 'DEFAULT';

	$_REQUEST {$name} =~ /^\d{8}$/ or die "#$name#:Код ОКПО должен состоять из 8 арабских цифр";
	
	my @n = split //, $_REQUEST {$name};
		
	my $checksum_1 =
		$n [0] * 1 +
		$n [1] * 2 +
		$n [2] * 3 +
		$n [3] * 4 +
		$n [4] * 5 +
		$n [5] * 6 +
		$n [6] * 7;
		
	$checksum_1 = $checksum_1 % 11;		

	my $checksum_2 =
		$n [0] * 3 +
		$n [1] * 4 +
		$n [2] * 5 +
		$n [3] * 6 +
		$n [4] * 7 +
		$n [5] * 8 +
		$n [6] * 9;
		
	$checksum_2 = $checksum_2 % 11;		
	$checksum_2 = 0 if $checksum_2 == 10;
	
	if ($checksum_1 > 9) {
		$checksum_2 == 0 + substr ($_REQUEST {$name}, -1, 1) or die "#$name#:Не сходится контрольная сумма ОКПО";
	}
	else {
		$checksum_1 == 0 + substr ($_REQUEST {$name}, -1, 1) or die "#$name#:Не сходится контрольная сумма ОКПО";
	}

	return undef;

}

################################################################################

sub vld_ogrn {

	my ($name, $nullable) = @_;
	
	$name = "_" . $name;
	
	if (!$_REQUEST {$name} && $nullable) {
		delete $_REQUEST {$name};
		return undef;
	}
	
	local $SIG {__DIE__} = 'DEFAULT';

	$_REQUEST {$name} =~ /^\d+$/ or return "#$name#:Код ОГРН[ИП] должен состоять из арабских цифр";
	$_REQUEST {$name} =~ /^[12]/    or die "#$name#:1-я цифра ОГРН[ИП] может быть только 1 (основной номер) или 2 (иной номер)";

	if (length $_REQUEST {$name} == 13) {
		(substr ($_REQUEST {$name}, 0, 12) % 11) % 10 == substr ($_REQUEST {$name}, -1, 1) or return "#$name#:Не сходится контрольная сумма ОГРН";
	}
	elsif (length $_REQUEST {$name} == 15) {
		(substr ($_REQUEST {$name}, 0, 14) % 13) % 10 == substr ($_REQUEST {$name}, -1, 1) or return "#$name#:Не сходится контрольная сумма ОГРНИП";
	}
	else {
		return "#$name#:ОГРН должен состоять из 13, а ОГРНИП из 15 арабских цифр";
	}

	return undef;
}

################################################################################

sub _vld_checksum {

	my ($number, $coef) = @_;
	
	my $sum = 0;
	
	for (my $i = 0; $i < length ($number); $i++) {
	
		$sum += $coef -> [$i] * substr ($number, $i, 1);
	
	}
	
	return $sum;

}

################################################################################

sub vld_bank_corr_account {

	my ($bik, $account) = @_;
	
	return 0 == (_vld_checksum (
		'0' . substr ($bik, 4, 2) . $account, 
		[7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1]
	) % 10)

}

################################################################################

sub vld_bank_account {

	my ($bik, $account) = @_;
	
	return 0 == (_vld_checksum (
		substr ($bik, -3, 3) . $account, 
		[7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1]
	) % 10)

}

################################################################################

sub vb {

	$_REQUEST {__vb_cnt} ++;
	
	my $key = "__vb_$_REQUEST{__vb_cnt}";
	
	exists $_REQUEST {$key} and return $_REQUEST {$key};
	
	my ($code) = @_;
	
	$code =~ /vb\s\=*/ism or $code = "vb = $code";
	
	my $inputs = '';
	my $length = 0;
	
	foreach my $k (keys %_REQUEST) {
		
		next if $k eq '__vb_cnt';
		
		my $v = $_REQUEST {$k};
		
		next if ref $v;
		next if $v eq '';
		next if $v eq 'lang';
		
		$length += length (uri_escape ($v));
		$length += length ($k);
		$length += 2;

		$v =~ s{\'}{&apos;}gsm;
		
		$inputs .= "<input type='hidden' name='$k' value='$v'>";		
		
	}
	
	my $method = $length > 1000 ? 'POST' : 'GET';
	
	out_html ({}, <<EOH);
<html>
	<head>
		<script language="vbscript">
			function vb ()
			  $code
			end function			
		</script>
		<script language="jscript">
			function l () {
				var f = document.forms['f'];
				f.elements['$key'].value = vb ();
				f.submit ();
			}
		</script>
	</head>
	<body onLoad="l()">
		<form name=f method=$method>
			<input type="hidden" name="__no_back" value="1">
			<input type="hidden" name="$key" value="">
			$inputs
		</form>
	</body>
</html>
EOH

	$_REQUEST {__response_sent} = 1;
	
	exit;

}

################################################################################

sub vb_yes {

	my ($message, $title, $default_button) = @_;
	
	$title ||= '';

	$default_button = 0 unless ($default_button == 1);

	return 6 == vb (qq{MsgBox ("$message", 4 + $default_button * 256, "$title")});

}

1;