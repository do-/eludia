no warnings;

################################################################################

sub memory_usage {

    foreach my $proc (@{$main::proc_processtable_object -> table}) {

        return $proc -> rss if $proc -> pid eq $$;

    }

};

################################################################################

BEGIN {

	$main::proc_processtable_object ||= new Proc::ProcessTable (cache_ttys => 1);

	loading_log 'ProcessTable';

}

1;
