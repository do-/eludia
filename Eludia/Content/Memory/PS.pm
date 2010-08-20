no warnings;

################################################################################

sub memory_usage {

	# UNIX95 - http://forums13.itrc.hp.com/service/forums/questionanswer.do?admit=109447627+1280205257988+28353475&threadId=943707

	my $cmd = $^O eq 'hpux' ? "UNIX95=ps -p $$ -o vsz" : "ps -p $$ -o rss";
 
	(`$cmd` =~ /(\d+)/) [0] << 10;

};

################################################################################

BEGIN {

	loading_log '`ps`';

}

1;
