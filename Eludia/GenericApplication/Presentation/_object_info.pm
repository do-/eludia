################################################################################

sub draw_item_of__object_info {

	my ($data) = @_;

	draw_form (
	
		{
			no_edit => 1,
		},
		
		$data,
		
		[
			[
				{
					label => 'id',
					value => $_REQUEST {id},
				},
				{
					label => 'type',
					value => $_REQUEST {object_type},
				},
			],
			[
				{
					label => 'label',
					value => $data -> {label},
				},
				{
					label => 'fake',
					value => $data -> {fake},
				},
			],
			
			{type => 'banner', label => 'LOG'},
			
			[
				{
					label  => 'when created',
					value  => $data -> {last_create} -> {dt},
					href   => "/?type=log&__popup=1&id=" . $data -> {last_create} -> {id},
					target => '_blank',
				},
				{
					label => 'when updated',
					value => $data -> {last_update} -> {dt},
					href  => "/?type=log&__popup=1&id=" . $data -> {last_update} -> {id},
					target => '_blank',
				},
			],
			[
				{
					label  => 'who created',
					value  => $data -> {last_create} -> {user} -> {label},
					href   => "/?type=users&id=" . $data -> {last_create} -> {id_user},
				},
				{
					label  => 'who updated',
					value  => $data -> {last_update} -> {user} -> {label},
					href   => "/?type=users&id=" . $data -> {last_update} -> {id_user},
				},
			],
			
		],
	
	)
	
	.
	
	draw_table (
	
		[
			'table',
			'column',
			'count',
		],
		
		sub {
		
			draw_cells ({
				href => {table_name => $i -> {table_name}, name => $i -> {name}},
			}, [
				$i -> {table_name},
				$i -> {name},
				{
					label   => $i -> {cnt},
					picture => '### ### ### ### ###',
					off     => 'if zero',
				},
			])
		
		},
		
		$data -> {references},
		
		{
			title => {label => 'References'},
			lpt => 1,
		},
	
	)
	
	.
	
	draw_table (
	
		[
			'id',
			'label',
			'dt',
		],
	
		sub {
			
			$i -> {dt} =~ s{(\d+)\-(\d+)\-(\d+)}{$3.$2.$1};
		
			draw_cells ({
				href => "/?type=$_REQUEST{table_name}&id=$$i{id}",
			}, [
				$i -> {id},
				$i -> {label} || $i -> {no},
				$i -> {dt},
			])
		
		},
		
		$data -> {records},
		
		{
			title => {label => "Referring $_REQUEST{table_name} by $_REQUEST{name}"},
			off => !$_REQUEST {table_name},
			top_toolbar => [{}, {
				type => 'pager',
				cnt  => 0 + @{$data -> {records}},
				total => $data -> {cnt},
			}],
			
		},
	
	)
	
}

1;