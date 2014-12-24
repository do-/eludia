package Eludia::Presentation::Skins::Mint;

use Data::Dumper;
use Storable ('freeze');

no warnings;

BEGIN {

	require Eludia::Presentation::Skins::Generic;
	delete $INC {"Eludia/Presentation/Skins/Generic.pm"};
	our $lrt_bar = '<!-- L' . ('o' x 8500) . "ong comment -->\n";

	our $replacement = {
		error    => 'JS',
		redirect => 'JS',
	};

}

################################################################################

sub is_ua_mobile {

	return 1; #$r -> headers_in -> {'User-Agent'} =~ /mobile|android/i;

}

################################################################################

sub options {

	return {
		core_unblock_navigation => $preconf -> {core_unblock_navigation},
		static_path             => '/i/mint/',
		skip_menu_ajusting      => 1,
	};

}

################################################################################

sub register_hotkey {

	my ($_SKIN, $hashref) = @_;

	$hashref -> {label} =~ s{\&(.)}{<u>$1</u>} or return undef;

	return undef if $_REQUEST {__edit};

	my $c = $1;

	if ($c eq '<') {
		return 37;
	}
	elsif ($c eq '>') {
		return 39;
	}
	elsif (lc $c eq 'Ê') {
		return 186;
	}
	elsif (lc $c eq '˝') {
		return 222;
	}
	else {
		$c =~ y{…÷” ≈Õ√ÿŸ«’⁄‘€¬¿œ–ŒÀƒ∆›ﬂ◊—Ã»“‹¡ﬁÈˆÛÍÂÌ„¯˘Áı˙Ù˚‚‡ÔÓÎ‰Ê˝ˇ˜ÒÏËÚ¸·˛}{qwertyuiop[]asdfghjkl;'zxcvbnm,.qwertyuiop[]asdfghjkl;'zxcvbnm,.};
		return (ord ($c) - 32);
	}

}

################################################################################

sub static_path {

	my ($package, $file) = @_;
	my $path = __FILE__;

	$path    =~ s{\.pm}{/$file};

	return $path;

};

################################################################################

sub draw_hr {

	my ($_SKIN, $options) = @_;

	return <<EOH;
EOH

}

################################################################################

sub draw_gantt_bars {

	my ($_SKIN, $options) = @_;

	my $top = 5;
	my $html = '';

	$options -> {plan} -> {color} ||= 'blue';
	$options -> {fact} -> {color} ||= 'red';

	foreach my $key ('plan', 'fact') {

		my $bar = $options -> {$key};

		my @pf = split /-/, $bar -> {from};
		my $dpf = $pf [2] / 30;

		my @pt = split /-/, $bar -> {to};
		my $dpt = $pf [2] / 30;

		$html .= <<EOH;
			<td style="
				border:solid black 1px;
				height:7px;
				z-index:0;
				position:absolute;
				top:  expression(this.previousSibling.offsetTop + $top);
				left: expression(getElementById('gantt_$pf[0]_$pf[1]').offsetLeft + $dpf * getElementById('gantt_$pf[0]_$pf[1]').offsetWidth);
				width:expression(getElementById('gantt_$pt[0]_$pt[1]').offsetLeft + $dpt * getElementById('gantt_$pt[0]_$pt[1]').offsetWidth - getElementById('gantt_$pf[0]_$pf[1]').offsetLeft - $dpf * getElementById('gantt_$pf[0]_$pf[1]').offsetWidth);
				background-color:$bar->{color}
			" title="$bar->{title}"><img src='$_REQUEST{__static_url}/0.gif' width=1 height=1></td>
EOH

		$top = 6;

	}

	return $html;

}

################################################################################

sub draw_auth_toolbar {

	my ($_SKIN, $options) = @_;

	return '';

}

################################################################################

sub draw_window_title {

	my ($_SKIN, $options) = @_;

	if ($_REQUEST {select}) {

		$_REQUEST {__script} .= <<EOJ;
			top.document.title = '$$options{label}';
EOJ
		return '';

	} else {

		return <<EOH
			<table cellspacing=0 cellpadding=0 width="100%"><tr><td class="table_title"><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 height=29 align=absmiddle>&nbsp;&nbsp;&nbsp;$$options{label}</td></tr></table>
EOH

	}

}

################################################################################
# FORMS & INPUTS
################################################################################

sub _draw_bottom {

	my ($_SKIN, $options) = @_;

	unless ($options -> {menu}) {
		return '';
	}

	my $html = '';
	my $items = $options -> {menu};

	foreach my $item (@$items) {
		if ($item -> {is_active}) {
			$html .='<li class="k-state-active k-item k-tab-on-top k-state-default k-first">
					<a id="'.$item.'" href="'.$$item{href}.'" class="tab-1 k-link" target="'.$item->{target}.'"><nobr>&nbsp;'.$$item{label}.'&nbsp;</nobr></a>
				</li>'
		} else {
			$html .= '<li class="k-item k-state-default">
					<a id="'.$item.'" href="'.$$item{href}.'" class="tab-0 k-link" target="'.$item->{target}.'"><nobr>&nbsp;'.$$item{label}.'&nbsp;</nobr></a>
				</li>'
		}

	}

	return <<EOH;
		<div class="k-widget k-header k-tabstrip">
				<ul class="k-tabstrip-items k-reset tabbb">$html</ul>
		</div>
EOH

}

################################################################################

sub _draw_input_datetime {

	return '' if $_REQUEST {__only_field};

	$_REQUEST {__libs} -> {kendo} -> {datetimepicker} = 1;

	my ($_SKIN, $options) = @_;

	$options -> {id} ||= '' . $options;

	$options -> {onClose}    ||= 'null';
	$options -> {onKeyDown}  ||= 'null';
	$options -> {onChange}   ||= 'null';
	$options -> {onKeyPress} ||= 'if (event.keyCode != 27) is_dirty=true';

	$options -> {attributes} -> {class} .= ' form-mandatory-inputs'
		if $options -> {mandatory} ;

	$options -> {attributes} -> {class} ||= 'form-active-inputs';

	my $attributes = dump_attributes ($options -> {attributes});

	my $picker_type = $options -> {no_time}? 'datepicker' : 'datetimepicker';
	my $html = <<EOH;
	<nobr>
		<input data-type="$picker_type"
			type="text"
			name="$$options{name}"
			$attributes
			onKeyPress="$$options{onKeyPress}"
			onKeyDown="$$options{onKeyDown}"
			onChange="$$options{onChange}"
		>
	</nobr>
EOH

	return $html;

}

################################################################################

sub draw_form {

	my ($_SKIN, $options) = @_;

	if ($_REQUEST {__only_field} || $_REQUEST {__only_table}) {
		return '';
	}

	my $html = $options -> {hr};


	$html .= $options -> {path};

	$html .= _draw_bottom (@_);

	$html .=  <<EOH;
			<form
				name="$$options{name}"
				target="$$options{target}"
				method="$$options{method}"
				enctype="$$options{enctype}"
				action="$_REQUEST{__uri}"
				autocomplete="off"
			>
			<input type=hidden name="__suggest" value="">
EOH

	$html .= dump_hiddens (

		map {[$_ -> {name} => $_ -> {value}]}

			@{$options -> {keep_params}}

	);
	$html .=  <<EOH;
			<table cellspacing=0 width="100%" style="border-style:solid; border-top-width: 1px; border-left-width: 1px; border-bottom-width: 0px; border-right-width: 0px; border-color: #d6d3ce;">
EOH
	foreach my $row (@{$options -> {rows}}) {
		my $tr_id = $row -> [0] -> {tr_id};
		$tr_id = 'tr_' . Digest::MD5::md5_hex ('' . $row) if 3 == length $tr_id;
		$html .= qq{<tr id="$tr_id">};
		foreach (@$row) { $html .= $_ -> {html} };
		$html .= qq{</tr>};
	}

	$html .=  '</table></form>';

	$html .= $options -> {bottom_toolbar};

	return $html;

}


################################################################################

sub draw_path {

	my ($_SKIN, $options, $list) = @_;

	$options -> {style} ||= $options -> {nowrap} ? qq{style="background:url('$_REQUEST{__static_url}/bgr_grey.gif?$_REQUEST{__static_salt}');background-repeat:repeat-x;"} : '';

	my $path = <<EOH;
		<div class="k-grouping-header fixed-header">&nbsp;
EOH

	my $icon = $options -> {status} ? "status_$options->{status}->{icon}.png" : 'i_folder.gif';

	$path .= qq{<div class="bgBreadcrumbsIcon" style="background-image:url($_REQUEST{__static_url}/path_folder.png?$_REQUEST{__static_salt})"></div>};

	for (my $i = 0; $i < @$list; $i ++) {

		if ($i > 0) {
			$path .= '&nbsp;/&nbsp;';
			if ($options -> {multiline}) {
				$path .= '<br>';
				for (my $j = 0; $j < $i + 2; $j++) { $path .= '&nbsp;&nbsp;' }
			}
		}

		my $item = $list -> [$i];

		$path .= qq{<a class=path ${\($$item{href} ? "href='$$item{href}'" : '')} TABINDEX=-1>$$item{label}</a>};

	}

	$path .= <<EOH;
&nbsp;</div>
EOH

	return $path;

}

################################################################################

sub draw_form_field {

	my ($_SKIN, $field, $data) = @_;

	if ($field -> {type} eq 'banner') {
		my $colspan     = 'colspan=' . ($field -> {colspan} + 1);
		return qq{<td class='form-$$field{state}-banner' $colspan nowrap align=center>$$field{html}</td>};
	}
	elsif ($field -> {type} eq 'article') {
		my $colspan     = 'colspan=' . ($field -> {colspan} + 1);
		return qq{<td $colspan class='form-article'>$$field{html}</td>};
	}
	elsif ($field -> {type} eq 'hidden') {
		return $field -> {html};
	}

	if ($field -> {plus}) {

		my $a = {

			height  => 18,
			src     => "$_REQUEST{__static_url}/tree_nolines_plus.gif?$_REQUEST{__static_salt}",
			width   => 18,
			border  => 0,
			align   => 'absmiddle',
			onClick => "clone_form_tr_for_this_plus_icon(this)",
			name    => 1,

		};


		if ($field -> {plus} =~ s{ (\d+)$}{}) {

			$a -> {name} = $1 - 1;

		}

		$a     -> {lowsrc} = $field -> {plus};

		$field -> {html } .= dump_tag (img => $a);

	}

	my $html = '';

	my $class = 'form-' . $field -> {state} . '-';

	unless ($field -> {label_off}) {

		my $a = {
			class  => $class . 'label',
			nowrap => 1,
			align  => 'right',
		};

		$a -> {colspan} = $field -> {colspan_label} if $field -> {colspan_label};
		$a -> {width}   = $field -> {label_width}   if $field -> {label_width};
		$a -> {title}   = $field -> {label_title}   if $field -> {label_title};

		$html .= dump_tag (td => $a, $field -> {label});

	}

	my $a = {class  => $class . ($field -> {fake} == -1 ? 'deleted' : 'inputs')};

	$a -> {colspan} = $field -> {colspan}    if $field -> {colspan};
	$a -> {width}   = $field -> {cell_width} if $field -> {cell_width};

	$html .= dump_tag (td => $a, $field -> {html});

	return $html;

}

################################################################################

sub draw_form_field_banner {
	my ($_SKIN, $field, $data) = @_;
	return $field -> {label};
}

################################################################################

sub draw_form_field_button {

	my ($_SKIN, $options, $data) = @_;

	$_REQUEST {__libs} -> {kendo} -> {button} = 1;

	return qq {<input type="button" name="_$$options{name}" value="$$options{value}" onClick="$$options{onclick}" tabindex=$tabindex>};

}

################################################################################

sub draw_form_field_string {

	my ($_SKIN, $options) = @_;

	my $attributes = $options -> {attributes};

	$attributes -> {onKeyPress} .= ';if (event.keyCode != 27) is_dirty=true;';
	$attributes -> {onKeyDown}  .= ';tabOnEnter();';
	$attributes -> {onFocus}    .= ';stibqif (true);';
	$attributes -> {onBlur}     .= ';stibqif (false);';

	$attributes -> {class}      .= ' k-textbox ';

	$attributes -> {type}        = 'text';

	return dump_tag ('input', $attributes);

}

################################################################################

sub draw_form_field_suggest {

	my ($_SKIN, $options, $data) = @_;

	$_REQUEST {__libs} -> {kendo} -> {autocomplete} = 1;

	my $values = $_JSON -> encode ([]);
	if (ref $options -> {values} ne 'CODE') {
		$values = $_JSON -> encode ([map {[$_ -> {id}, $_ -> {label}]} @{$options -> {values}}]);
	}

	$options -> {attributes} ||= {};
	my $attr_input = $options -> {attributes};
	my $id = $options -> {name} || 'suggest';

	$attr_input -> {id}                  = $id;
	$attr_input -> {size}              ||= $options -> {size} || 60;
	$attr_input -> {"data-role"}         = "autocomplete";
	$attr_input -> {"a-data-values"}     = $values
		if $values;
	$attr_input -> {"a-data-url"}        = "$ENV{REQUEST_URI}&__suggest=$options->{name}";
	$attr_input -> {"a-data-min-length"} = $options -> {min_length}
		if $options -> {min_length} && $options -> {min_length} != 1;

	$attr_input -> {"a-data-change"}     = "$$options{after}"
		if $options -> {after};


	return dump_tag (input => $options -> {attributes})

		. dump_tag (input => {
			type  => 'hidden',
			id    => "${id}__label",
			name  => "_$options->{name}__label",
			value => $options -> {attributes} -> {value},
		})

		. dump_tag (input => {
			type     => 'hidden',
			id       => "${id}__id",
			name     => "_$options->{name}__id",
			value    => $options -> {value__id},
			onchange => $options -> {after},
		});



}

################################################################################

sub draw_form_field_datetime {

	my ($_SKIN, $options, $data) = @_;

	$options -> {name} = '_' . $options -> {name};
	$options -> {onKeyDown} ="tabOnEnter()";

	return $_SKIN -> _draw_input_datetime ($options);

}

################################################################################

sub draw_form_field_file {

	my ($_SKIN, $options, $data) = @_;

	$_REQUEST {__libs} -> {kendo} -> {upload} = 1;

	my $attributes = dump_attributes ($options -> {attributes});

	my $html = "<span id='form_field_file_head_$options->{name}'>";

	$$options{value} ||= $data -> {file_name};

	if ($options -> {can_edit}) {
		if ($options -> {value} || ($data -> {file_name} && $data -> {file_path})) {
			$_REQUEST {__on_load} .= "\$('#file_input_$$options{name}').hide();";
		} else {
			$_REQUEST {__on_load} .= "\$('#file_name_$$options{name}').hide();";
		}

		$html .= <<EOH;
			<span id='file_name_$$options{name}'>
				$$options{value}
				<img id='img_$$options{name}' height=12 src='$_REQUEST{__static_url}/files_delete.png?$_REQUEST{__static_salt}' width=12 border=0 align=absmiddle'
					onclick="javascript: \$('#file_input_$$options{name}').show(); \$('#file_name_$$options{name}').hide(); \$('#_file_clear_flag_for_$$options{name}').val(1);">
			</span>
			<span id='file_input_$$options{name}'>
EOH
	}

	$html .= <<EOH;
			<input
				type="file"
				name="_$$options{name}"
				size=$$options{size}
				$attributes
				onFocus="stibqif (true);"
				onBlur="stibqif (false);"
				onChange="is_dirty=true; $$options{onChange}"
				onKeyDown="if (event.keyCode != 9) return false;"
				tabindex=-1
				data-ken-multiple="false"
			/>
EOH

	$html .= <<EOH if ($options -> {can_edit});
		</span>
		<input type='hidden' name='_file_clear_flag_for_$$options{name}' id='_file_clear_flag_for_$$options{name}'>
EOH

	$html .= "</span>";

	return $html;

}

################################################################################

sub draw_form_field_files {

	my ($_SKIN, $options, $data) = @_;

	$_REQUEST {__libs} -> {kendo} -> {upload} = 1;

	$_REQUEST {__script} .= <<'EOJS' if $_REQUEST {__script} !~ /function number_file_fields_for_compatibility/;
	function number_file_fields_for_compatibility (file_field) {
		var next_counter = 1 + parseInt(file_field.name.match(/\d+$/)[0]);
		file_field.name = file_field.name.replace(/\d+$/, next_counter);
	}
EOJS

	$options -> {attributes} -> {"data-ken-multiple"} = "true";
	$options -> {attributes} -> {onchange} = "number_file_fields_for_compatibility(this)";

	my $attributes = dump_attributes ($options -> {attributes});

	return <<EOH;

		<input
			type="hidden"
			name="__$$options{name}_file_field"
			value="$options->{field}"
		>

		<input
			type="hidden"
			name="__$$options{name}_file_no_del"
			value="$options->{no_del}"
		>
		<span id="file_field_$options->{name}">
			<span id="file_field_$options->{name}_head">
				<input name="_$$options{name}_0" type="file" $attributes />
			</span>
		</span>

EOH

}

################################################################################

sub draw_form_field_hidden {

	my ($_SKIN, $options, $data) = @_;

	return dump_tag (input => {
		type  => 'hidden',
		name  => '_' . $options -> {name},
		value => $options -> {value},
	});

}

################################################################################

sub draw_form_field_hgroup {

	my ($_SKIN, $options, $data) = @_;
	my $html = '';

	$html .= '<nobr>'
		if ($options -> {nobr});

	foreach my $item (@{$options -> {items}}) {
		next if $item -> {off};
		$html .= $item -> {label} if $item -> {label};
		$html .= $item -> {html};
		$html .= '&nbsp;';
	}

	$html .= '</nobr>'
		if ($options -> {nobr});

	return $html;

}

################################################################################

sub draw_form_field_text {

	my ($_SKIN, $options, $data) = @_;

	$options -> {attributes} -> {class} .= ' k-textbox ';

	my $attributes = dump_attributes ($options -> {attributes});

	my $url = 'mint/libs/jquery.autosize.min';

	unless (grep {$_ eq $url} @{$_REQUEST {__include_js}}) {

		push @{$_REQUEST{__include_js}}, $url;

		$_REQUEST {__on_load} .= ';$("textarea").autosize();';

	}

	return <<EOH;
		<textarea
			$attributes
			onFocus="stibqif (true);"
			onBlur="stibqif (false);"
			rows=$$options{rows}
			cols=$$options{cols}
			name="_$$options{name}"
			onchange="is_dirty=true;"
		>$$options{value}</textarea>
EOH

}

################################################################################

sub draw_form_field_password {
	my ($_SKIN, $options, $data) = @_;

	$options -> {attributes} -> {class} .= ' k-textbox ';
	$options -> {attributes} -> {autocomplete} = 'off';

	my $attributes = dump_attributes ($options -> {attributes});

	return qq {<input type="password" name="_$$options{name}" size="$$options{size}" onKeyPress="if (event.keyCode != 27) is_dirty=true" $attributes onKeyDown="tabOnEnter()" onFocus="stibqif (true)" onBlur="stibqif (false)">};
}

################################################################################

sub draw_form_field_static {

	my ($_SKIN, $options, $data) = @_;

	my $html = '';

	if ($options -> {href}) {
		my $state = $_REQUEST {__read_only} ? 'passive' : 'active';
		$options -> {a_class} ||= "form-$state-inputs";
		$options -> {a_class} =~ s{(passive|active)}{deleted} if ($data -> {fake} == -1);
		$html = qq{<a href="$$options{href}" target="$$options{target}" class="$$options{a_class}">};
	}

	if (ref $options -> {value} eq ARRAY) {

		$options -> {separator} ||= '<br>';

		for (my $i = 0; $i < @{$options -> {value}}; $i++) {

			if ($i) {
				$html =~ s{\s*$}{};
				$html =~ s{\s*$}{$options->{separator}};
			}

			$html .= $options -> {value} -> [$i] -> {label};

		}

	}
	else {
		$html .= $options -> {value};
		$html .= '&nbsp;' if $options -> {value} eq '';
	}


	if ($options -> {href}) {
		$html .= '</a>';
	}

	$html .= dump_hiddens ([$options -> {hidden_name} => $options ->{hidden_value}]) if $options -> {add_hidden};

	return "<span id='input_$$options{name}'>$html</span>";

}

################################################################################

sub draw_form_field_checkbox {

	my ($_SKIN, $options, $data) = @_;

	my $attributes = dump_attributes ($options -> {attributes});

	return qq {<input class=cbx type="checkbox" name="_$$options{name}" id="input_$$options{name}" $attributes $checked value=1 onChange="is_dirty=true" onKeyDown="tabOnEnter()">};

}

################################################################################

sub draw_form_field_radio {

	my ($_SKIN, $options, $data) = @_;

	my $html = qq {<table border=0 cellspacing=2 cellpadding=0 width=100% id='input_$$options{name}'><tr>};

	my $n = 0;

	my @ids = map {'' . $_} grep {$_ -> {html}} @{$options -> {values}};

	if (@ids) {

		$options -> {refresh_name} = "refresh_radio_$options->{name}";

		$_REQUEST {__script} .= qq {

			function $options->{refresh_name} () {@{[ map {"refresh_radio__div ('$_');"} @ids ]}}

		};

	}

	foreach my $value (@{$options -> {values}}) {

		my $a = $value -> {attributes};

		$a -> {type}       = 'radio';
		$a -> {class}    ||= 'cbx';
		$a -> {name}       = '_' . $options -> {name};
		$a -> {value}      = $value -> {id};
		$a -> {id}         = ''  . $value;
		$a -> {onFocus}   .= ";stibqif (true)";
		$a -> {onBlur}    .= ";stibqif (true)";
		$a -> {onClick}   .= $value -> {onclick} . ";is_dirty=true";
		$a -> {onClick}   .= ";$options->{refresh_name}()" if $options -> {refresh_name};
		$a -> {onKeyDown} .= ";tabOnEnter()";

		$html .= '<td class="form-inner" width=1 nowrap="1">';

		$html .= dump_tag (input => $a);

		$html .= qq {</td><td class="form-inner" width=1><nobr>&nbsp;<label for="$value">$$value{label}</label></nobr>};

		if ($value -> {html}) {

			my $bn = $a -> {checked} ? 'block' : 'none';

			$html .= qq {<td class="form-inner"><div id="radio_div_$value" style="display:$bn">$$value{html}</div>};

		}

		$options -> {no_br} or ++ $n == @{$options -> {values}} or $html .= qq {<td class="form-inner"><div>&nbsp;</div><tr>};

	}

	$html .= '<td class="form-inner"><div>&nbsp;</div></table>';

	return $html;

}

################################################################################

sub draw_form_field_select {

	my ($_SKIN, $options, $data) = @_;

	return $_SKIN -> draw_form_field_combo ($options, $data)
		if $options -> {ds};

	$_REQUEST {__libs} -> {kendo} -> {dropdownlist} = 1;

	$options -> {attributes} ||= {};
	$options -> {attributes} -> {id}    ||= $options -> {id} || "_$options->{name}_select";

	if (
		@{$options -> {values}} == 0
		&&
		defined ($options -> {empty}) && defined ($options -> {other})
	) {
		$options -> {attributes} -> {'data-ken-autoopen'} = 1;
	}

	my $attributes = dump_attributes ($options -> {attributes});

	if (defined $options -> {other}) {

		$options -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 'dialog_width';
		$options -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 'dialog_height';

		$options -> {no_confirm} ||= $conf -> {core_no_confirm_other};

		$options -> {onChange} = <<EOJS;

			if (this.options[this.selectedIndex].value == -1) {

				open_vocabulary_from_select (
					this,
					{
						message       : '$i18n->{choose_open_vocabulary}',
						href          : '$options->{other}->{href}&select=$options->{name}&salt=' + Math.random(),
						dialog_width  : $options->{other}->{width},
						dialog_height : $options->{other}->{height},
						title         : '$i18n->{voc_title}'
					}
				);

			} else {
				$options->{onChange}
			}

EOJS

	}

	my $html = <<EOH;
		<select
			name="_$$options{name}"
			$attributes
			onKeyDown="tabOnEnter();"
			onChange="is_dirty=true; $$options{onChange}"
			onKeyPress="typeAhead(0);"
			onKeyUp="var keyCode = event.keyCode || event.which; if (keyCode == 38 || keyCode == 40) this.onchange();"
		>
EOH

	if (defined $options -> {empty}) {
		$html .= qq {<option value="0" $selected>$$options{empty}</option>\n};
	}

	if (defined $options -> {other} && $options -> {other} -> {on_top}) {
		$html .= qq {<option value=-1>${$$options{other}}{label}</option>};
	}

	foreach my $value (@{$options -> {values}}) {
		$html .= qq {<option value="$$value{id}" $$value{selected}>$$value{label}</option>\n};
	}

	if (defined $options -> {other} && !$options -> {other} -> {on_top}) {
		$html .= qq {<option value=-1>${$$options{other}}{label}</option>};
	}

	$html .= '</select>';

	return $html;

}

################################################################################

sub draw_form_field_combo {

	my ($_SKIN, $options, $data) = @_;

	$_REQUEST {__libs} -> {kendo} -> {combobox} = 1;

	$options -> {attributes} ||= {};

	$options -> {attributes} -> {id}    ||= ($options -> {id} ||= "_$options->{name}_select");

	$options->{max_len} ||= 0;

	$options -> {attributes} -> {onFocus}   .= ";stibqif (true,true)";
	$options -> {attributes} -> {onBlur}    .= ";stibqif (true,false)";

	my $attributes = dump_attributes ($options -> {attributes});

	if (defined $options -> {other}) {

		$options -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 'screen.availWidth - (screen.availWidth <= 800 ? 50 : 100)';
		$options -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 'screen.availHeight - (screen.availHeight <= 600 ? 50 : 100)';


	}

	my $values = $_JSON -> encode ($options -> {values} || []);
	$values =~ s/\"/'/g;

	check_href ($options -> {ds});

	my $html = <<EOH;
		<span style="white-space: nowrap;" id="input_$options->{name}"><input name="_$$options{name}" $attributes onKeyDown="tabOnEnter();" onChange="is_dirty=true; $$options{onChange}">
EOH

	if (defined $options -> {other}) {
		$html .= <<EOH;
			<input type="button" class="k-button" value="..."
				onClick="open_vocabulary_from_combo (
					\$('#$options->{attributes}->{id}').data('kendoComboBox'),
					{
						message       : i18n.choose_open_vocabulary,
						href          : '$options->{other}->{href}&select=$options->{name}&salt=' + Math.random(),
						dialog_width  : $options->{other}->{width},
						dialog_height : $options->{other}->{height},
						title         : '$i18n->{voc_title}'
					}
				);"
				tabindex=$tabindex
			>
EOH
	}

	$html .= '</span>';

	local $conf -> {portion} ||= 50;

	$options -> {ds} -> {href} = ''
		if $options -> {ds} -> {off};

	$_REQUEST {__on_load} .= <<EOJS;

		if (window.name.substring (0, 9) == 'invisible') {
			setTimeout (
				function () {
					parent.do_kendo_combo_box ('$options->{attributes}->{id}', {
						values  : $values,
						empty   : '$options->{empty}',
						href    : '$options->{ds}->{href}',
						portion : $conf->{portion},
						max_len : $options->{max_len}
					});
				},
				10
			);
		} else {
			do_kendo_combo_box ('$options->{attributes}->{id}', {
				values  : $values,
				empty   : '$options->{empty}',
				href    : '$options->{ds}->{href}',
				portion : $conf->{portion},
				max_len : $options->{max_len}
			});
		}

EOJS


	return $html;

}

################################################################################

sub draw_form_field_string_voc {

	my ($_SKIN, $options, $data) = @_;

	$options -> {attributes} ||= {};

	$options -> {attributes} -> {onKeyPress} .= qq[;if (event.keyCode != 27) {is_dirty=true;document.getElementById('${options}_id').value = 0; }];
	$options -> {attributes} -> {onKeyDown}  .= qq[;if (event.keyCode == 8 || event.keyCode == 46) {is_dirty=true;document.getElementById('${options}_id').value = 0;}; tabOnEnter();];
	$options -> {attributes} -> {onFocus}    .= ';stibqif (true);';
	$options -> {attributes} -> {onBlur}     .= ';stibqif (false);';
	$options -> {attributes} -> {onChange}   .= 'is_dirty=true;' . ( $options->{onChange} ? $options->{onChange} . ' try { event.cancelBubble = false } catch (e) {} try { event.returnValue = true } catch (e) {}': '');

	my $attributes = dump_attributes ($options -> {attributes});

	if (defined $options -> {other}) {

		$options -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 'screen.availWidth - (screen.availWidth <= 800 ? 50 : 100)';
		$options -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 'screen.availHeight - (screen.availHeight <= 600 ? 50 : 100)';

		$options -> {other} -> {onChange} .= <<EOJS;

			var dialog_width = $options->{other}->{width};
			var dialog_height = $options->{other}->{height};

			var q = encode1251(document.getElementById('${options}_label').value);

			if (\$.browser.webkit || \$.browser.safari)
				\$.blockUI ({fadeIn: 0, message: '<h1>$i18n->{choose_open_vocabulary}</h1>'});
			var result = window.showModalDialog ('$ENV{SCRIPT_URI}/i/_skins/Mint/dialog.html?@{[rand ()]}', {href: '$options->{other}->{href}&$options->{other}->{param}=' + q + '&select=$options->{name}&$options->{other}->{cgi_tail}', parent:window}, 'status:no;resizable:yes;help:no;dialogWidth:' + dialog_width + 'px;dialogHeight:' + dialog_height + 'px');

			if (\$.browser.webkit || \$.browser.safari)
				\$.unblockUI ();
			focus ();

			if (result.result == 'ok') {
				document.getElementById('${options}_label').value=result.label;
				document.getElementById('${options}_id').value=result.id;
$options->{onChange}
			} else {
				this.selectedIndex = 0;
			}
EOJS
	}


	my $html = qq[<span style="white-space: nowrap" id="_$options->{name}_span"><input type="text" $attributes id="${options}_label" >]

		. ($options -> {other} ? qq [ <input type="button" value="..." onclick="$options->{other}->{onChange}">] : '')

		. dump_tag (input => {

			type  => "hidden",
			name  => "_$options->{name}",
			value => "$options->{id}",
			id    => "${options}_id",

		})

		. '</span>';

	return $html;

}

################################################################################

sub draw_form_field_tree {

	my ($_SKIN, $options, $data) = @_;

	$_REQUEST {__libs} -> {kendo} -> {treeview} = 1;
	$_REQUEST {__libs} -> {kendo} -> {splitter} = 1;

	my %p2n = ();
	my %i2n = ();
	foreach my $i (@{$options -> {values}}) {

		my $n = $i -> {__node};

		my $nn = {
			id          => $i -> {id},
			parent      => $i -> {parent},
			text        => $n -> {name},
			is_checkbox => $n -> {is_checkbox},
			is_radio    => $n -> {is_radio},
		};

		$nn -> {imageUrl} = _icon_path ($n -> {icon}) if $n -> {icon};

		push @{$p2n {0 + $i -> {parent}} ||= []}, $nn;

		$i2n {$i -> {id}} = $nn;

	}

	if (my $id = $options -> {selected_node}) {

		while (my $nn = $i2n {$id}) {
			$nn -> {expanded} = \1;
			$id = $nn -> {parent};
		}
	} elsif (@{$p2n {0}} == 1) {
		$p2n {0} -> [0] -> {expanded} = \1;
	}

	foreach my $nn (values %i2n) {

		my $items = $p2n {$nn -> {id}} or next;

		$nn -> {items} = $items;

	}

	my $data = $_JSON -> encode ($p2n {0} ||= []);

	my $name = $options -> {name} || 'd';
	$options->{height} ||= 200;

	$_REQUEST {__on_load} .= <<EOJS;
 \$("#${name}_treeview").kendoTreeView({
	checkboxes: {
		template: "#if(item.is_checkbox > 0 || item.is_radio > 0){# <input type='#if(item.is_checkbox){#checkbox#}else{#radio#}#' name='_${name}_#=item.id#' value='1' #if(item.is_checkbox == 2){# checked #}#/> #}#"
	},
	dataSource: {
		data : $data
	}
});
EOJS

	return qq {
		<div style="height: $options->{height}px" id="${name}_treeview"></div>
	};


}

################################################################################

sub draw_form_field_checkboxes {

	my ($_SKIN, $options, $data) = @_;

	my $html = '';

	my $tabindex = $_REQUEST {__tabindex} + 1;

	my $v = $data -> {$options -> {name}};

	if (ref $v eq ARRAY) {

		my $n = 0;

		$html .= '<table border=0 cellpadding=0 cellspacing=0><tr>';

		foreach my $value (@{$options -> {values}}) {

			my $checked = 0 + (grep {$_ eq $value -> {id}} @$v) ? 'checked' : '';

			my $id = 'div_' . $value;
			my $subhtml = '';
			my $subattr = '';

			my $display = $checked || $options -> {expand_all} ? '' : 'style={display:none}';

			if ($value -> {html}) {
				$subhtml .= $value -> {inline} ? qq{&nbsp;<span id="$id" $display>} : qq{&nbsp;</td><td class="form-inner" id="$id" $display>};
				$subhtml .= $value -> {html};
				$subhtml .= $value -> {inline} ? qq{</span>} : '';
				$subattr = qq{onClick="setVisible('$id', checked)"} unless $options -> {expand_all};
			}
			elsif ($value -> {items} && @{$value -> {items}} > 0) {

				foreach my $subvalue (@{$value -> {items}}) {

					my $subchecked = 0 + (grep {$_ eq $subvalue -> {id}} @$v) ? 'checked' : '';

					$tabindex++;

					$subhtml .= $subvalue -> {no_checkbox} ? qq{&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$$subvalue{label} <br>} : qq {&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input id="$subvalue" class=cbx type="checkbox" name="_$$options{name}_$$subvalue{id}" value="1" $subchecked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;<label for="$subvalue">$$subvalue{label}</label><br>};

				}


				$subhtml = <<EOH;
					<div id="$id" $display>
						$subhtml
					</div>
EOH

				$subattr = qq{onClick="setVisible('$id', checked)"} unless $options -> {expand_all};

			}

			$tabindex ++;
			$n ++;

			$html .= qq {<td class="form-inner"><input id="$value" $subattr class=cbx type="checkbox" name="_$$options{name}_$$value{id}" value="1" $checked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;<label for="$value">$$value{label}</value> $subhtml</td>};
			$html .= '</tr><tr>' unless $n % $options -> {cols};

		}

		$html =~ s{\<tr\>$}{};
		$html .= '</table>';

	}
	else {

		foreach my $value (@{$options -> {values}}) {
			my $checked = $v eq $value -> {id} ? 'checked' : '';
			$tabindex++;
			$html .= qq {<input class=cbx type="checkbox" name="_$$options{name}" value="$$value{id}" $checked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;$$value{label} <br>};
		}

	}

	if ($options -> {height}) {
		$html = <<EOH;
			<div class="checkboxes" style="height:$$options{height}px;" id="input_$$options{name}">
				$html
			</div>
EOH
	}
	else {
		$html = <<EOH;
			<span id="input_$$options{name}">
				$html
			</span>
EOH
	}

	$_REQUEST {__tabindex} = $tabindex;

	return $html;

}

################################################################################

sub draw_form_field_image {

	my ($_SKIN, $options, $data) = @_;

	return <<EOH;
		<input type="hidden" name="_$$options{name}" value="$$options{id_image}">
		<img src="$$options{src}" id="$$options{name}_preview" width = "$$options{width}" height = "$$options{height}">&nbsp;
		<input type="button" value="$$i18n{Select}" onClick="nope('$$options{new_image_url}', 'selectImage' , '');">
EOH

}

################################################################################

sub draw_form_field_iframe {

	my ($_SKIN, $options, $data) = @_;

	return <<EOH;
		<iframe name="$$options{name}" src="$$options{href}" width="$$options{width}" height="$$options{height}" application="yes"></iframe>
EOH

}

################################################################################

sub draw_form_field_color {

	my ($_SKIN, $options, $data) = @_;

	my $html = <<EOH;
		<table
			id="td_color_$$options{name}"
			align="absmiddle"
			cellspacing=0
			cellpadding=0
			style="height:20px;width:40px;border:solid black 1px;background-color:#$$options{value}"
EOH

	# —Ú‡Ì‰‡ÚÌ‡ˇ Ô‡ÎËÚ‡

	my $palette_file = 'colors.html';
	my $dialog_width = '600px';
	my $dialog_height = '400px';

	# œ‡ÎËÚ‡ Excel 2010

	if ($options -> {palette} eq 'excel2010') {

		$palette_file = 'excel_colors.html';
		$dialog_width = '300px';
		$dialog_height = '250px';

	}

	if (!$_REQUEST {__read_only}) {

		$html .= <<EOH;
			onClick="
				var color = showModalDialog('$_REQUEST{__static_url}/colors.html?$_REQUEST{__static_salt}', window, 'dialogWidth:600px;dialogHeight:400px;help:no;scroll:no;status:no');
				getElementById('td_color_$$options{name}').style.backgroundColor = color;
				getElementById('input_color_$$options{name}').value = color.substr (1);
			"
EOH

	}

	$html .= <<EOH;
		>
			<tr height=20>
				<td>
					<input id="input_color_$$options{name}" type="hidden" name="_$$options{name}" value="$$options{value}">
				</td>
			</tr>
		</table>
EOH

	return $html;

}

################################################################################

sub draw_form_field_htmleditor {

	my ($_SKIN, $options, $data) = @_;

	return '' if $options -> {off};

	push @{$_REQUEST{__include_js}}, 'rte/fckeditor';

	return <<EOH;
		<SCRIPT language="javascript">
			<!--
				var oFCKeditor_$$options{name};
				oFCKeditor_$$options{name} = new FCKeditor('_$$options{name}', '$$options{width}', '$$options{height}', '$$options{toolbar}');
				oFCKeditor_$$options{name}.Value = '$$options{value}';
				oFCKeditor_$$options{name}.Create ();
			//-->
		</SCRIPT>
EOH

}

################################################################################

sub draw_form_field_multi_select {

	my ($_SKIN, $options, $data) = @_;

	$_REQUEST {__libs} -> {kendo} -> {multiselect} = 1;

	$options -> {attributes} ||= {};
	$options -> {attributes} -> {id}    ||= $options -> {id} || "_$options->{name}_multi_select";

	ref $options -> {ds} eq HASH or $options -> {ds} = {href => $options -> {ds}};

	check_href ($options -> {ds});

	my $values = $_JSON -> encode ([map {{id => $_ -> {id}, label => $_ -> {label}}} @{$options -> {values}}]);

	$_REQUEST {__on_load} .= <<EOJS;
		var multi_select = \$("#$options->{attributes}->{id}").kendoMultiSelect({
			dataTextField: "label",
			dataValueField: "id",
			autoBind: false,
			dataSource: {
				serverFiltering: true,
				transport: {
					read: {
						url         : '$options->{ds}->{href}' + '&salt=' + Math.random (),
						contentType : 'application/x-www-form-urlencoded; charset=UTF-8'
					},
					dataType    : 'json',
					parameterMap: function(data, type) {
						var q;
						if (data.filter && data.filter.filters && data.filter.filters [0] && data.filter.filters [0].value)
							q = data.filter.filters [0].value;

						if (type == 'read') {
							return {
								start   : data.skip,
								portion : data.take,
								ids     : data.ids,
								q       : q
							}
						}
					}

				},
				serverPaging    : true,
				pageSize        : $conf->{portion},
				schema   : {
					total : 'cnt',
					data  : function (result) {
						return result.result;
					}
				}
			},
			dataBound: function(e) {
				if (this.value ().join () != \$("INPUT[name=_$$options{name}]").val())
					this.value (\$("INPUT[name=_$$options{name}]").val().split(','));
			},
			value: $values,
			change: function(e) {
				var value = this.value();
				\$("INPUT[name=_$$options{name}]").val(value.join());
			}
		}).data("kendoMultiSelect");
EOJS


	if ($options -> {mandatory}) {
		$_REQUEST {__on_load} .= <<'EOJS';
			multi_select.input.parent().addClass ('form-mandatory-inputs');
EOJS
	}

	my $attributes = dump_attributes ($options -> {attributes});
	my $ids = join (',', map {$_ -> {id}} @{$options -> {values}});

	my $after = <<EOJS;
		if (typeof result !== 'undefined' && result.result == 'ok') {
			var multi_select = \$("#$options->{attributes}->{id}").data("kendoMultiSelect");
			multi_select.dataSource.query({
				ids : result.ids
			});
			result.ids = result.ids.replace (/-1,/, '');
			multi_select.value (result.ids.split (','));
			\$("INPUT[name='_$$options{name}'").val (result.ids);
		}
		setCursor ();
EOJS

	my $url = &{$_PACKAGE . 'dialog_open'} ({
		href  => $options -> {href} . '&multi_select=1',
		title => $label,
		after => $after,
	});

	$url =~ s/^javascript://i;
	my $url_dialog_id = $_REQUEST {__dialog_cnt};


	return <<EOH;
		<select multiselect name="_$$options{name}_src" $attributes></select><input type="hidden" name="_$$options{name}" value="$ids">
		<input type="button" class="k-button" value="..."
			onClick="re = /&_?salt=[\\d\\.]*/g; dialogs[$url_dialog_id].href = dialogs[$url_dialog_id].href.replace(re, ''); re = /&ids=[^&]*/i; dialogs[$url_dialog_id].href = dialogs[$url_dialog_id].href.replace(re, ''); dialogs[$url_dialog_id].href += '&salt=' + Math.random () + '&ids=' + document.getElementsByName ('_$options->{name}') [0].value;
			$url"
		>
EOH

}




################################################################################
# TOOLBARS
################################################################################

################################################################################

sub draw_toolbar {

	my ($_SKIN, $options) = @_;

	if ($_REQUEST {select}) {

		my $button = {
			icon    => 'cancel',
			id      => 'cancel',
			label   => $i18n -> {close},
			href    => is_ua_mobile () ? "javaScript:var i = 0, w = parent; for (i = 0; i < 5 && w.name != '_modal_iframe'; i ++) w = w.parent; if (w.name == '_modal_iframe') w.parent.\$('DIV.modal_div').dialog ('close');" : "javaScript:window.parent.close();",
		};

		$button -> {html} = $_SKIN -> draw_toolbar_button ($button);

		unshift @{$options -> {buttons}}, $button;

	}

	my $html = <<EOH;
	<form action="$_REQUEST{__uri}" name="$options->{form_name}" target="$$options{target}" class="toolbar">
EOH


	my %keep_params = map {$_ => 1} @{$options -> {keep_params}};

	$keep_params {$_} = 1 foreach qw (sid __last_query_string __last_scrollable_table_row __last_last_query_string);

	$html .= dump_hiddens (map {[$_ => $_REQUEST {$_}]} (keys %keep_params));

	$html .= <<EOH;
		<ul class="filters">
EOH
	foreach (@{$options -> {buttons}}) {
		$html .= $_ -> {html};
	}

	$html .= <<EOH;
		</ul>
		</form>
EOH

	return $html;

}

################################################################################

sub draw_toolbar_break {

	my ($_SKIN, $options) = @_;

	return $options -> {break_table} ? '</ul><ul class="filters">' : '';

}

################################################################################

sub _icon_path {

	-r $r -> document_root . "/i/images/icons/$_[0].png" ? "$_REQUEST{__static_site}/i/images/icons/$_[0].png" :
		-r $r -> document_root . "/i/_skins/Mint/i_$_[0].gif" ?	"$_REQUEST{__static_url}/i_$_[0].gif?$_REQUEST{__static_salt}" :
	"$_REQUEST{__static_site}/i/buttons/$_[0].gif"

}

################################################################################

sub draw_toolbar_button {

	my ($_SKIN, $options) = @_;

	$_REQUEST {__libs} -> {kendo} -> {button} = 1;

	my $html = <<EOH;
		<li>
EOH

	if ($options -> {items}) {

		$_REQUEST {__libs} -> {kendo} -> {menu} = 1;

		my $id = substr ("$$options{id}", 5, (length "$$options{id}") - 6);

		$html .= "<script>var data_$id = " . $_JSON -> encode ([
			map {
				$_ -> {imageUrl} = _icon_path ($_ -> {icon}) if $_ -> {icon};
				{
					text  => $_ -> {label},
					url   => $_ -> {href},
					imageUrl => $_ -> {imageUrl} || '',
					confirm => $_ -> {confirm} || '',
				}
			} @{$options -> {items}}
		]);
		$html .= "</script>";

		$html .= <<EOH;

			<a TABINDEX=-1 class="k-button" href="#" id="$id" target="$$options{target}" title="$$options{title}"><nobr>

			<script>

				setup_drop_down_button ("$id", data_$id);

			</script>
EOH
	} else {
		$html .= <<EOH;
			<a TABINDEX=-1 class="k-button" href="$$options{href}" $$options{onclick} id="$$options{id}" target="$$options{target}" title="$$options{title}"><nobr>
EOH
	}

	if ($options -> {icon}) {
		my $img_path = _icon_path ($options -> {icon});
		$html .= qq {<img src="$img_path" alt="$label" border=0 hspace=0 style='vertical-align:middle;'>};
	}

	$html .= <<EOH;
				$options->{label}</nobr>
				</a>
		</li>

EOH

	return $html;

}

################################################################################

sub draw_toolbar_input_tree {

	my ($_SKIN, $options) = @_;

	$_REQUEST {__libs} -> {kendo} -> {dropdownlist} = 1;
	$_REQUEST {__libs} -> {kendo} -> {treeview} = 1;
	push @{$_REQUEST{__include_js}}, 'libs/kendo.web.ext';

	my $id = "toolbar_input_tree_$options->{name}";

	my %p2n = ();
	my %i2n = ();
	foreach my $i (@{$options -> {values}}) {

		my $n = $i -> {__node};

		my $nn = {
			id          => $i -> {id},
			parent      => $i -> {parent},
			text        => $n -> {name},
			is_checkbox => $n -> {is_checkbox},
			is_radio    => $n -> {is_radio},
		};

		$nn -> {imageUrl} = _icon_path ($n -> {icon}) if $n -> {icon};

		push @{$p2n {0 + $i -> {parent}} ||= []}, $nn;

		$i2n {$i -> {id}} = $nn;

	}

	if (my $id = $options -> {selected_node}) {

		while (my $nn = $i2n {$id}) {
			$nn -> {expanded} = \1;
			$id = $nn -> {parent};
		}
	} elsif (@{$p2n {0}} == 1) {
		$p2n {0} -> [0] -> {expanded} = \1;
	}

	foreach my $nn (values %i2n) {

		my $items = $p2n {$nn -> {id}} or next;

		$nn -> {items} = $items;

	}

	my $data = $_JSON -> encode ($p2n {0} ||= []);
	my $name = $options -> {name};
	my $value = $options -> {label};
	$value =~ s/\"/\\"/g;

	$options -> {height} ||= 400;
	$options -> {width}  ||= 600;
	my $dropdown_width = $options -> {max_len} * 3;

	$_REQUEST {__on_load} .= <<EOJS;
var ${id}_changed;
var ${id}_el = \$("#$id").kendoExtDropDownTreeView({
	dropDownWidth : $dropdown_width,
	value      : "$value",
	tree_close : function (e) {
		if (${id}_changed) {
			\$("#toolbar_input_tree_id_dep").parents("FORM").submit ();
		}
	},
	treeview   : {
		width      : $options->{width},
		height     : $options->{height},
		checkboxes : {
			template: "#if(item.is_checkbox > 0 || item.is_radio > 0){# <input type='#if(item.is_checkbox){#checkbox#}else{#radio#}#' name='${name}_#=item.id#' value='1' #console.log(item); if(item.is_checkbox == 2){# checked #}#/> #}#"
		},
		dataSource : {
			data : $data
		}
	}
});
\$("INPUT[type='checkbox'][name^='${name}_']").change(function () {${id}_changed = 1});
EOJS


	return qq|<li class="toolbar nowrap"><div id="$id"></div></li>|;



}

################################################################################

sub draw_toolbar_input_select {

	my ($_SKIN, $options) = @_;

	return $_SKIN -> draw_toolbar_input_combo ($options)
		if $options -> {ds} && !$options -> {read_only};

	$_REQUEST {__libs} -> {kendo} -> {dropdownlist} = 1;

	my $html = '<li class="toolbar nowrap">';

	if ($options -> {label} && $options -> {show_label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$options -> {name} = '_' . $options -> {name}
		if defined $options -> {other};

	my $name = $$options{name};

	my $read_only = $options -> {read_only} ? 'disabled' : '';

	if (defined $options -> {other}) {

		$options -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 'dialog_width';
		$options -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 'dialog_height';

		$options -> {no_confirm} ||= $conf -> {core_no_confirm_other};
		my $submit;
		if ($options -> {onChange} =~ s/(submit\(\);)$//) {
			$submit = $1;
		}

		$options -> {onChange} .= <<EOJS;
			if (this.options[this.selectedIndex].value == -1) {

				open_vocabulary_from_select (
					this,
					{
						message       : i18n.choose_open_vocabulary,
						href          : '$options->{other}->{href}&select=$name&salt=' + Math.random(),
						dialog_width  : $options->{other}->{width},
						dialog_height : $options->{other}->{height},
						title         : '$i18n->{voc_title}'
					}
				);

			} else {

				if (\$.data (this, 'prev_value') != this.selectedIndex) {
					$submit;
				}

			}
EOJS

	} # defined $options -> {other}

	$options -> {attributes} ||= {};

	$options -> {attributes} -> {onChange} = $options -> {onChange};
	$options -> {attributes} -> {onFocus} = q|$.data (this, 'prev_value', this.selectedIndex);|;

	$options -> {attributes} -> {onKeyPress} = 'typeAhead(1)';

	my $attributes = dump_attributes ($options -> {attributes});

	$html .= <<EOH;
		<select name="$name" id="${name}_select"  $read_only $attributes>
EOH

	foreach my $value (@{$options -> {values}}) {

		my $attributes = dump_attributes ($value -> {attributes});

		$html .= qq {<option value="$$value{id}" $$value{selected} $attributes>$$value{label}</option>};

	}

	$html .= '</select></li>';

	return $html;

}

################################################################################

sub draw_toolbar_input_combo {

	my ($_SKIN, $options) = @_;

	$_REQUEST {__libs} -> {kendo} -> {combobox} = 1;

	my $html = '<li class="toolbar nowrap">';

	if ($options -> {label} && $options -> {show_label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$options -> {name} = '_' . $options -> {name}
		if defined $options -> {other};

	my $name = $$options{name};

	$options -> {attributes} ||= {};

	$options -> {attributes} -> {id}    ||= "${name}_select";
	$options -> {attributes} -> {onChange} = $options -> {onChange};

	my $attributes = dump_attributes ($options -> {attributes});

	if (defined $options -> {other}) {

		$options -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 'screen.availWidth - (screen.availWidth <= 800 ? 50 : 100)';
		$options -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 'screen.availHeight - (screen.availHeight <= 600 ? 50 : 100)';


	}

	my ($values, $placeholder);
	foreach my $value (@{$options -> {values}}) {
		if (!$value -> {id}) {
			$placeholder = $value -> {label};
			push @$values, $value;
		} elsif ($value -> {id} != -1) {
			push @$values, $value;
		}
	}


	$values = $_JSON -> encode ($values);
	$values =~ s/\"/'/g;

	check_href ($options -> {ds});

	$html .= <<EOH;
		<input name="$name" $attributes>
EOH

	if (defined $options -> {other}) {
		$html .= <<EOH;
			<input type="button" class="k-button" value="..."
				onClick="open_vocabulary_from_combo (
					\$('#$options->{attributes}->{id}').data('kendoComboBox'),
					{
						message       : i18n.choose_open_vocabulary,
						href          : '$options->{other}->{href}&select=$name&salt=' + Math.random(),
						dialog_width  : $options->{other}->{width},
						dialog_height : $options->{other}->{height}
					}
				);"
			>
EOH
	}

	$html .= '</li>';

	local $conf -> {portion} ||= 50;

	$options -> {ds} -> {href} = ''
		if $options -> {ds} -> {off};

	$_REQUEST {__on_load} .= <<EOJS;
		do_kendo_combo_box ('$options->{attributes}->{id}', {
			values  : $values,
			empty   : '$options->{empty}',
			href    : '$options->{ds}->{href}',
			portion : $conf->{portion},
			width   : @{[$options -> {attributes} -> {size} * 8]},
			placeholder : '$placeholder'
		});
EOJS


	return $html;




}

################################################################################

sub draw_toolbar_input_checkbox {

	my ($_SKIN, $options) = @_;

	my $html = '<li class="toolbar nowrap">';

	if ($options -> {label}) {
		$html .= qq {<label for="$options">$$options{label}:</label>};
	}

	$html .= qq {<input id="$options" class=cbx type=checkbox value=1 $$options{checked} name="$$options{name}" onClick="$$options{onClick}">};

	$html .= "</li>";

	return $html;

}

################################################################################

sub draw_toolbar_input_files {

	my ($_SKIN, $options) = @_;

	$_REQUEST {__libs} -> {kendo} -> {button} = 1;

	my $html = <<EOH;
		<li>
EOH

	my $name = "_$$options{name}_1";

	$options -> {href} = "javascript: \$('input[name=$name]').click()";


	my $keep_form_params = $options -> {keep_form}? <<EOJS : '';
		\$(this.form).filter('[isacopy]').remove();

		var \$originalInputs = \$('form[name=$$options{keep_form}] :input').not(':submit');

		\$originalInputs.clone().hide().attr('isacopy','y').appendTo(\$(this.form))
			.each(function(i, el) {
				\$(el).val(\$originalInputs.eq(i).val())
			});

		var \$originalSelects = \$('form[name=$$options{keep_form}] > select');

		\$originalSelects.clone().hide().attr('isacopy','y').appendTo(\$(this.form))
			.each(function(i, el) {
				\$(el).val(\$originalSelects.eq(i).val())
			});
EOJS

	$options -> {onChange} = "javascript:" . $keep_form_params . <<'EOJS';

		var toolbarFormData = new FormData(this.form);

		toolbarFormData.append('action', 'upload');

		$.ajax ({
			type: 'POST',
			url: '/',
			data: toolbarFormData,
			processData: false,
			contentType : false,
			dataType: 'json',
			success: function(data) {
				if (data.message) {
					alert(data.message);
					return;
				}
				location.reload(true);
			},
			error: function(data) {
				console.log(data);
			}
		});
EOJS

	$html .= <<EOH;
			<a TABINDEX=-1 class="k-button" href="$$options{href}" $$options{onclick} id="$$options{id}" target="$$options{target}" title="$$options{title}"><nobr>
EOH

	$html .= <<EOH;
				<input
					type="file"
					name="$name"
					$attributes
					onFocus="scrollable_table_is_blocked = true; q_is_focused = true"
					onBlur="scrollable_table_is_blocked = false; q_is_focused = false"
					onChange="is_dirty=true; $$options{onChange}"
					style="visibility:hidden; width: 1px"
					multiple="multiple"
					data-ken-multiple="true"
					is-native="true"
				/>
EOH



	if ($options -> {icon}) {
		my $img_path = _icon_path ($options -> {icon});
		$html .= qq {<img src="$img_path" alt="$label" border=0 hspace=0 style='vertical-align:middle;'>};
	}

	$html .= <<EOH;
				$options->{label}</nobr>
				</a>
		</li>

EOH

	return $html;

}

################################################################################

sub draw_toolbar_input_submit {

	my ($_SKIN, $options) = @_;

	my $html = '<li class="toolbar nowrap">';

	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= qq {<input type=submit name="$$options{name}" value="$$options{label}">};

	$html .= "</li>";

	return $html;

}

################################################################################

sub draw_toolbar_input_text {

	my ($_SKIN, $options) = @_;

	my $html = '<li nowrap class="toolbar">';

	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}


	$options -> {attributes} ||= {};

	$options -> {onKeyPress} ||= "if (event.keyCode == 13) {form.submit(); blockEvent ()}";

	my $attributes = dump_attributes ($options -> {attributes});

	$html .= <<EOH;
		<input
			onKeyPress="$$options{onKeyPress};"
			type=text
			size=$$options{size}
			name=$$options{name}
			value="$$options{value}"
			onFocus="stibqif (true)"
			onBlur="stibqif (false)"
			$attributes
			class="k-textbox"
			id="$options->{id}"
		>
EOH
	$html .= "</li>";

	return $html;

}

################################################################################

sub draw_toolbar_input_datetime {

	my ($_SKIN, $options) = @_;

	$options -> {onClose}    = "function (cal) { cal.hide (); $$options{onClose}; cal.params.inputField.form.submit () }";
	$options -> {onKeyPress} = "if (event.keyCode == 13) {this.form.submit()}";
	$options -> {onChange}   = join ';', $options -> {onChange}, "submit ()"
		if !$options -> {no_change_submit};

	my $html = '<li class="toolbar nowrap">';

	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$options -> {attributes} -> {class} ||= ' ';

	$html .= $_SKIN -> _draw_input_datetime ($options);

	$html .= "</li>";

	return $html;

}

################################################################################

sub draw_toolbar_input_file {

	my ($_SKIN, $options) = @_;

	$_REQUEST {__libs} -> {kendo} -> {upload} = 1;

	my $html = '<li class="toolbar nowrap">';

	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= <<EOH;
			<input
				type="file"
				name="_$$options{name}"
				size=$$options{size}
				tabindex=-1
				data-ken-multiple="false"
				data-upload-url="$$options{href}"
			/></li>
EOH


	return $html;



}

################################################################################

sub draw_toolbar_pager {

	my ($_SKIN, $options) = @_;

	return '<li role="header" class="toolbar_pager"></li>';

}

################################################################################

sub draw_toolbar_button_vert_menu {

	$_REQUEST {__libs} -> {kendo} -> {menu} = 1;

}

################################################################################

sub draw_centered_toolbar_button {

	my ($_SKIN, $options) = @_;

	$_REQUEST {__libs} -> {kendo} -> {button} = 1;

	my $img_path = "$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}";

	if ($options -> {icon}) {
		$img_path = _icon_path ($options -> {icon});
	}

	if ($preconf -> {core_blockui_on_submit} && $options -> {blockui}) {

		unless ($options -> {href} =~ /^javaScript\:/i) {

			$options -> {target} ||= '_self';

			$options -> {href} =~ s{\%}{\%25}g;

			$options -> {href} = qq {javascript: nope('$options->{href}','$options->{target}')};

			$options -> {target} = '_self';

		}

		$options -> {href} =~ s/\bnope\b/blockui ('', 1);nope/;

	}

	my $nbsp = $options -> {label} ? '&nbsp;' : '';

	my $html = "<td nowrap>";

	if ($options -> {items}) {

		my $id = substr ("$$options{id}", 5, (length "$$options{id}") - 6);

		$html .= "<script>var data_$id = " . $_JSON -> encode ([
			map {
				$_ -> {imageUrl} = _icon_path ($_ -> {icon}) if $_ -> {icon};
				{
					text  => $_ -> {label},
					url   => $_ -> {href},
					imageUrl => $_ -> {imageUrl} || '',
					confirm => $_ -> {confirm} || '',
				}
			} @{$options -> {items}}
		]);
		$html .= "</script>";

		$html .= <<EOH;

			<a TABINDEX=-1 class="k-button" href="#" id="$id" target="$$options{target}" title="$$options{title}"><nobr>

			<script>

				setup_drop_down_button ("$id", data_$id);

		</script>
EOH

	} else {
		$html .= <<EOH;
			<a class="k-button" href="$$options{href}" $$options{onclick} id="$$options{id}" target="$$options{target}" title="$$options{title}"><nobr>
EOH
	}

	$html .= <<EOH;
			<img src="$img_path" border="0" hspace="0" style="vertical-align:middle;">
			${nbsp}
			<nobr class="smallizer_text">
				$$options{label}
			</nobr>
		</a>
	</td>
	<td><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=10 border=0></td>
EOH


}

################################################################################

sub draw_centered_toolbar {

	my ($_SKIN, $options, $list) = @_;

	our $__last_centered_toolbar_id = 'toolbar_' . int $list;

	my $colspan = 3 * (1 + $options -> {cnt}) + 1;

	my $html = <<EOH;
		<table class="centered_toolbar">
			<tr>
				<td colspan=$colspan><div style="height:8px;"></div></td>
			</tr>
			<tr>
				<td width="45%">
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
						</tr>
					</table>
				</td>
EOH

	foreach (@$list) {
		$html .= $_ -> {html};
	}

	$html .= <<EOH;
				<td width="45%">
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
						</tr>
					</table>
				</td>
			</tr>
			<tr>
				<td colspan=$colspan><div style="height:8px;"></div></td>
			</tr>
		</table>
EOH

	return $html;

}

################################################################################

sub draw_dump_button {

	return {
		label  => 'Dump',
		name   => '_dump',
		href   => "javascript:_dumper_href('&__dump=1', 'invisible');",
		side   => 'right_items',
		no_off => 1,

	};
}

################################################################################
# MENUS
################################################################################

################################################################################

sub draw_menu {

	my ($_SKIN, $_options) = @_;


	return $_options;

}

################################################################################

sub draw_vert_menu {

	my ($_SKIN, $name, $types, $level, $is_main) = @_;

	$_REQUEST {__libs} -> {kendo} -> {menu} = 1;

	[map {

		ref $_ ne HASH ? () : {
			text  => $_ -> {label},
			url   => $_ -> {href},
			target => $_ -> {target},
			(!$_ -> {icon}  ? () : (imageUrl => _icon_path ($_ -> {icon}))),
			(!$_ -> {items} ? () : (items => $_SKIN -> draw_vert_menu ($_ -> {items}))),
		}

	} @$types];

}

################################################################################
# TABLES
################################################################################

################################################################################

sub js_set_select_option {

	my ($_SKIN, $name, $item, $fallback_href) = @_;

	return ($fallback_href || $i) unless $_REQUEST {select};

	$item -> {question} ||= "$i18n->{confirm_close_vocabulary} \"$item->{label}\"?" unless $conf -> {core_no_confirm_other};

	my $a = $_JSON -> encode ({
		id       => $item -> {id},
		label    => $item -> {label},
		question => $item -> {question},
	});

	return $_SO_VARIABLES -> {$a}
		if $_SO_VARIABLES -> {$a};

	my $var = "so_" . substr ('' . $item, 7, 7);
	$var =~ s/\)$//;

	my $i = 0;
	while (index ($_REQUEST {__script}, "var $var") != -1) {
		$var .= $i ++;
	}

	$_REQUEST {__script} .= " var $var = $a; ";

	$_SO_VARIABLES -> {$a} = "javaScript:invoke_setSelectOption ($var)";

	return $_SO_VARIABLES -> {$a};

}

################################################################################

sub draw_text_cell {

	my ($_SKIN, $data, $options) = @_;

	if (defined $data -> {level}) {

		$data -> {attributes} -> {style} .= ';padding-left:' . ($data -> {level} * 15 + 3);

	}

	$data -> {attributes} -> {class} .= ' row-cell-nowrap'
		if $data -> {attributes} -> {title} =~ /^\d+(\.\d+)?$/ || $data -> {attributes} -> {title} =~ /^\d{2}\.\d{2}\.\d{4} \d{1,2}\:\d{1,2}\:\d{1,2}/;

	$data -> {a_class} and $data -> {attributes} -> {class} .= ' ' . $data -> {a_class};

	my $fgcolor = $data -> {fgcolor} || $options -> {fgcolor};

	$data -> {attributes} -> {style} = join '; color:', $data -> {attributes} -> {style}, $fgcolor
		if $fgcolor;

	if ($data -> {href} && $data -> {href} ne $options -> {href}) {
		$data -> {attributes} -> {"data-href"} = $data -> {href};
		$data -> {attributes} -> {"data-href-target"} = $data -> {target}
			unless $data -> {target} eq '_self';
	}

	my $html = dump_tag ('td', $data -> {attributes});

	if ($data -> {__is_first_not_fixed_cell}) {
		$html = dump_tag ('td', {class => 'freezbar-cell'}) . $html;
	}

	if ($data -> {off} || $data -> {label} !~ s/^\s*(.+?)\s*$/$1/gsm) {

		return $html . '&nbsp;</td>';

	}

	$data -> {label} =~ s{\n}{<br>}gsm if $data -> {no_nobr};

	if ($data -> {status} && -r $r -> document_root . "$_REQUEST{__static_url}/status_$data->{status}->{icon}.gif") {
		$html .= qq {<img style="width:11px;height:11px;" src='$_REQUEST{__static_url}/status_$data->{status}->{icon}.gif' border=0 alt='$data->{status}->{label}' align=absmiddle hspace=5>};
	} elsif ($data -> {status} && -r $r -> document_root . "$_REQUEST{__static_url}/status_$data->{status}->{icon}.png") {
		$html .= qq {<img style="width:16px;height:16px;" src='$_REQUEST{__static_url}/status_$data->{status}->{icon}.png' border=0 alt='$data->{status}->{label}' align=absmiddle hspace=5>};
	}

	$html .= '<b>'      if $data -> {bold}   || $options -> {bold};
	$html .= '<i>'      if $data -> {italic} || $options -> {italic};
	$html .= '<strike>' if $data -> {strike} || $options -> {strike};

	$html .= $data -> {label};

	$html .= '</b>'      if $data -> {bold}   || $options -> {bold};
	$html .= '</i>'      if $data -> {italic} || $options -> {italic};
	$html .= '</strike>' if $data -> {strike} || $options -> {strike};

	$html .= '</td>';

	return $html;

}


################################################################################

sub draw_radio_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $$options{data} $attributes><input class=cbx type=radio name=$$data{name} $$data{checked} value='$$data{value}'></td>};

}

################################################################################

sub draw_datetime_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	local $options -> {name} = $data -> {name};

	return "<td $$options{data} $attributes>" . $_SKIN -> _draw_input_datetime ($data) . "</td>";

}

################################################################################

sub draw_checkbox_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	my $label = $data -> {label} ? '&nbsp;' . $data -> {label} : '';

	return qq {<td $$options{data} $attributes><input class=cbx type=checkbox name=$$data{name} $$data{checked} value='$$data{value}'>$label</td>};

}

################################################################################

sub draw_select_cell {

	my ($_SKIN, $data, $options) = @_;

	$_REQUEST {__libs} -> {kendo} -> {dropdownlist} = 1;

	my $s_attributes -> {class} = "form-mandatory-inputs" if $data -> {mandatory};
	$s_attributes = dump_attributes ($s_attributes);

	my $attributes = dump_attributes ($data -> {attributes});

	my $multiple = $data -> {rows} > 1 ? "multiple size=$$data{rows}" : '';

	$data -> {onChange} ||= $options -> {onChange};

	if (defined $data -> {other}) {

		$data -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 'dialog_width';
		$data -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 'dialog_height';

		$data -> {no_confirm} ||= $conf -> {core_no_confirm_other};

		$data -> {onChange} .= <<EOJS;

			if (this.options[this.selectedIndex].value == -1) {
				open_vocabulary_from_select (
					this,
					{
						message       : '$i18n->{choose_open_vocabulary}',
						href          : '$data->{other}->{href}&select=$data->{name}&salt=' + Math.random(),
						dialog_width  : $data->{other}->{width},
						dialog_height : $data->{other}->{height},
						title         : '$i18n->{voc_title}'
					}
				);

			}

EOJS

	}

	my $id_select = $data -> {id} || "_$data->{name}_select";

	my $html = qq {<td $attributes><select
		$s_attributes
		id="$id_select"
		name="$$data{name}"
		onChange="is_dirty=true; $$data{onChange}"
		onkeypress='typeAhead();'
		$multiple
	};

	$html .= '>';

	$html .= qq {<option value="0">$$data{empty}</option>\n} if defined $data -> {empty};

	if (defined $data -> {other} && $data -> {other} -> {on_top}) {
		$html .= qq {<option value=-1>${$$data{other}}{label}</option>};
	}

	foreach my $value (@{$data -> {values}}) {
		$html .= qq {<option value="$$value{id}" $$value{selected}>$$value{label}</option>\n};
	}

	if (defined $data -> {other} && !$data -> {other} -> {on_top}) {
		$html .= qq {<option value=-1>${$$data{other}}{label}</option>};
	}

	$html .= qq {</select></td>};

	return $html;

}


################################################################################

sub draw_string_voc_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	if (defined $data -> {other}) {

		$data -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 'screen.availWidth - (screen.availWidth <= 800 ? 50 : 100)';
		$data -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 'screen.availHeight - (screen.availHeight <= 600 ? 50 : 100)';

		$data -> {other} -> {onChange} .= <<EOJS;
			var dialog_width = $data->{other}->{width};
			var dialog_height = $data->{other}->{height};

			var q = encode1251(document.getElementById('$$data{name}_label').value);

			if (\$.browser.webkit || \$.browser.safari)
				\$.blockUI ({fadeIn: 0, message: '<h1>$i18n->{choose_open_vocabulary}</h1>'});
			var result = window.showModalDialog ('$ENV{SCRIPT_URI}/i/_skins/Mint/dialog.html?@{[rand ()]}', {href: '$data->{other}->{href}&$data->{other}->{param}=' + q + '&select=$data->{name}', parent: window}, 'status:no;resizable:yes;help:no;dialogWidth:' + dialog_width + 'px;dialogHeight:' + dialog_height + 'px');

			if (\$.browser.webkit || \$.browser.safari)
				\$.unblockUI ();
			focus ();

			if (result.result == 'ok') {
				document.getElementById('$$data{name}_label').value = result.label;
				document.getElementById('$$data{name}_id').value = result.id;
			}
EOJS
	}

	my $html = qq {<td $attributes><nobr><span style="white-space: nowrap"><input onFocus="q_is_focused = true; left_right_blocked = true;" onBlur="q_is_focused = false; left_right_blocked = false;" type="text" value="$$data{label}" name="$$data{name}_label" id="$$data{name}_label" maxlength="$$data{max_len}" size="$$data{size}"> }
		. ($data -> {other} ? qq [<input type="button" value="$data->{other}->{button}" onclick="$data->{other}->{onChange}">] : '')
		. dump_tag (input => {

			type  => "hidden",
			name  => "_$data->{name}",
			value => "$data->{id}",
			id    => "$data->{name}_id",

		})
		. '</span></nobr></td>';

	return $html;

}

################################################################################

sub draw_input_cell {

	my ($_SKIN, $data, $options) = @_;

	my $autocomplete;
	my $attr_input = {
		onBlur    => 'q_is_focused = false; left_right_blocked = false;',
		onKeyDown => 'tabOnEnter();',
		class     => 'k-textbox',
	};
	$attr_input -> {class} .= ' table-mandatory-inputs'
		if $data -> {mandatory};


	if ($data -> {autocomplete}) {

		$_REQUEST {__libs} -> {kendo} -> {autocomplete} = 1;

		my $a_options = $data -> {autocomplete};

		my $values = $_JSON -> encode ([]);
		if (ref $a_options -> {values} ne 'CODE') {
			$values = $_JSON -> encode ([map {[$_ -> {id}, $_ -> {label}]} @{$a_options -> {values}}]);
		}

		my $id = '' . $data -> {autocomplete}  . "_$$data{name}";
		$id =~ s/[\(\)]//g;

		$attr_input -> {id} = $id;
		$attr_input -> {"data-role"} = "autocomplete";
		$attr_input -> {"a-data-values"} = $values
			if $values;
		$attr_input -> {"a-data-url"} = "$ENV{REQUEST_URI}&__suggest=$$data{name}";
		$attr_input -> {"a-data-min-length"} = $a_options -> {min_length}
			if $a_options -> {min_length} && $a_options -> {min_length} != 3;


		$autocomplete = dump_tag (input => {
			type  => 'hidden',
			id    => "$data->{name}__suggest",
			name  => "$data->{name}__suggest",
			value => $data -> {value},
		});

		$_REQUEST {__script} .= $js;

	}

	my $attributes = dump_attributes ($data -> {attributes});
	$attr_input = dump_attributes ($attr_input);

	$data -> {label} =~ s{\"}{\&quot;}gsm;

	my $tabindex = 'tabindex=' . (++ $_REQUEST {__tabindex});

	return qq {<td $$data{title} $attributes><nobr><input onFocus="q_is_focused = true; left_right_blocked = true;" $attr_input name="$$data{name}" value="$$data{label}" maxlength="$$data{max_len}" size="$$data{size}" $tabindex>$autocomplete</nobr></td>};

}

################################################################################

sub draw_row_button {

	my ($_SKIN, $options) = @_;

	if ($options -> {off} || $_REQUEST {lpt}) {
		return '';
	}

	my $vert_line = {
		label  => $options -> {label},
		href   => $options -> {href},
		target => $options -> {target},
		icon   => $options -> {icon},
	};

	push @{$_SKIN -> {__current_row} -> {__types}}, $vert_line;

	return '';

}


####################################################################

sub draw_table_header {

	my ($_SKIN, $data_rows, $html_rows) = @_;

	my $html = '<thead>';
	foreach (@$html_rows) {$html .= $_};
	$html .= '</thead>';

	return $html;

}

####################################################################

sub draw_table_header_row {

	my ($_SKIN, $data_cells, $html_cells) = @_;

	return ''
		unless @$html_cells;

	my $html = '<tr>';
	foreach (@$html_cells) {$html .= $_};
	$html .= '</tr>';

	return $html;

}

####################################################################

sub draw_table_header_cell {

	my ($_SKIN, $cell) = @_;

	return '' if $cell -> {hidden} || $cell -> {off} || (!$cell -> {label} && $conf -> {core_hide_row_buttons} == 2);

	$cell -> {attributes} -> {style} = 'z-index:' . ($cell -> {no_scroll} ? 110 : 100) . ';' . $cell -> {attributes} -> {style};

	!$cell -> {width} or $cell -> {attributes} -> {style} .= " width: $$cell{width}px;";
	!$cell -> {height} or $cell -> {attributes} -> {style} .= " height: $$cell{height}px;";

	$cell -> {id} ||= &{$_PACKAGE . 'get_super_table_cell_id'} ($cell);
	$cell -> {attributes} -> {id} ||= $cell -> {id};
	$cell -> {attributes} -> {class} ||= $cell -> {class};

	if ($cell -> {order}) {
		$cell -> {attributes} -> {class} .= " sortable";
	}

	my $html = dump_tag (th => $cell -> {attributes}, $cell -> {label});

	if ($cell -> {__is_first_not_fixed_cell}) {
		$html = dump_tag ('th', {class => 'freezbar-cell'}) . $html;
	}

	return $html;

}

####################################################################

sub draw_super_table__only_table {

	my ($_SKIN, $tr_callback, $list, $options) = @_;

	if ($_REQUEST {__only_table} && $_REQUEST {__only_table} ne $options -> {id_table}) {
		return '';
	}

	my $html = "<table id='$$options{id_table}'>";

	$options -> {header} ||= '<thead></thead>';
	$html .= $options -> {header};

	$html .= qq {<tbody>};

	my $row_cnt = 0;

	foreach our $i (@$list) {

		my $tr_cnt = 0;

		foreach my $tr (@{$i -> {__trs}}) {


			my $attributes = {};

			$attributes = dump_attributes ($attributes);

			$html .= "<tr id='$$i{__tr_id}' $attributes";

			if ($i -> {__menu}) {

				my $context_menu = $_JSON -> encode ($i -> {__menu});
				$context_menu =~ s/\"/&quot;/g;
				$html .= qq { data-menu="$context_menu" };
			}

			my $has_href = $i -> {__href} -> [$tr_cnt] && ($_REQUEST {__read_only} || !$_REQUEST {id} || $options -> {read_only});

			if ($has_href) {

				$html .= qq { data-target="$i->{__target}->[$tr_cnt]"}
					if $i -> {__target} -> [$tr_cnt] && $i -> {__target} -> [$tr_cnt] ne '_self';

				$html .= qq { data-href="$i->{__href}->[$tr_cnt]"};

			}

			$html .= '>';
			$html .= $tr;
			$html .= '</tr>';
			$row_cnt++;
			$tr_cnt++;
		}
	}

	$html .= '</tbody></table>';

	my $columns = [];

	my $header_rows = $options -> {headers};

	ref $header_rows -> [0] eq ARRAY or $header_rows = [$header_rows];

	my $matrix;

	for (my $row = 0; $row < @$header_rows; $row ++) {
		foreach my $cell (@{$header_rows -> [$row]}) {
			my $col = @{$matrix -> [$row]};
			$cell -> {id} ||= "coord_$row_$col";
			my $cell_cnt_to_insert = $cell -> {colspan} || 1;
			for (my $i = 0; $i < $col && $cell_cnt_to_insert > 0; $i ++) {
				if (!defined ($matrix -> [$row] -> [$i])) {
					$matrix -> [$row] -> [$i] = $cell;
					$cell_cnt_to_insert --;
				}
			}
			push @{$matrix -> [$row]}, ($cell) x $cell_cnt_to_insert
				if $cell_cnt_to_insert > 0;
			for (my $rowspan = 1; $rowspan < $cell -> {rowspan}; $rowspan ++) {
				$matrix -> [$row + $rowspan] -> [$col + rowspan] = $cell;
			}
		}
	}

	for (my $row = 1; $row < @$matrix; $row ++) {
		for (my $col = 0; $col < @{$matrix -> [$row]}; $col ++) {
			my $cell = $matrix -> [$row] -> [$col];


			my $parent = $matrix -> [$row - 1] -> [$col];
			unless ($cell -> {id} eq $parent -> {id}) {
				$cell -> {parent} = $parent;
			}

		}
	}

	my $is_set_all_headers_width  = 1;
	local $settings = exists $_QUERY -> {content} -> {columns}? $_QUERY -> {content} -> {columns} : {};

	my $_adjust_cell_hash = sub {

		my ($column) = @_;

		$column -> {id} = $column -> {order} || $column -> {no_order} || $column -> {id},

		$column -> {sortable} = $column -> {order} && (
			$_REQUEST {order} eq $column -> {id}
			|| !$_REQUEST {order} && $settings -> {$column -> {id}} -> {sort}
		);

		my $sort_direction = $settings -> {$column -> {id}} -> {desc} ? "desc" : "asc";

		my $width = $settings -> {$column -> {id}} -> {width} || undef;

		return {
			id                                       => $column -> {id},
			($width ? (width                         => $width) : ()),
			($column -> {sortable}? (sort            => "1") : ()),
			($column -> {sortable}? ($sort_direction => "1") : ()),
			($column -> {group} ? (group             => $column -> {group}) : ()),
		}

	};


	for (my $row = 0; $row < @$matrix - 1; $row ++) {
		for (my $col = 0; $col < @{$matrix -> [$row]}; $col ++) {
			my $cell = $matrix -> [$row] -> [$col];
			foreach my $child (@{$matrix -> [$row + 1]}) {
				if ($child -> {parent} -> {id} eq $cell -> {id} && !grep {$child -> {id} eq $_ -> {id}} @{$cell -> {group}}) {
					push @{$cell -> {group}}, $_adjust_cell_hash -> ($child);
					$is_set_all_headers_width = 0
						unless $child -> {width};
				}
			}
		}
	}

	foreach my $cell (@{$matrix -> [0]}) {
		if (!grep {$cell -> {id} eq $_ -> {id}} @$columns) {
			push @$columns, $_adjust_cell_hash -> ($cell);
			$is_set_all_headers_width = 0
				unless $cell -> {width};
		}
	}

	$is_set_all_headers_width = 0
		unless @{$matrix -> [0]};


	my $table = {
		id          => $options -> {id_table},
		fix_columns => $options -> {__fixed_cols} + 0,
		fix_rows    => $options -> {fix_rows} + 0,
		columns     => $columns,
		total       => 0 + $options -> {pager} -> {total},
		cnt         => 0 + $options -> {pager} -> {cnt},
		portion     => 0 + $options -> {pager} -> {portion},
		start       => $_REQUEST {start} + 0,
		data        => $html,
		calculated_dimensions => {
			headers => $is_set_all_headers_width + 0,
			rows    => 0,
		},
		script      => $_REQUEST {__only_table} ? $_REQUEST {__script} . ';' . $_REQUEST {__on_load} : '',
	};

	return $_JSON -> encode ($table);
}


####################################################################

sub draw_table {

	my ($_SKIN, $tr_callback, $list, $options) = @_;

	my $data_json = $_SKIN -> draw_super_table__only_table ($tr_callback, $list, $options);

	return $data_json
		if $_REQUEST {__only_table};

	$_REQUEST {__script} = <<EOJS . $_REQUEST {__script};
		window.tables_data = window.tables_data || {};
		window.tables_data ['$options->{id_table}'] = $data_json;
EOJS

	my $height = $options -> {__height} || $options -> {min_height} || 100; # px

	$options -> {attributes} = {
		class               => "eludia-table-container",
		id                  => $options -> {id_table},
		style               => "height:$height px; width:100%;",
		"eludia-min-height" => $height,
	};

	my $attributes = dump_attributes ($options -> {attributes});

	my $html;

	$html = qq {<div $attributes></div>\n}
		unless index ($data_json, '<tr') == -1;

	my %hidden = ();

	$hidden {$_} = $_REQUEST {$_} foreach (
		'__tree',
		'__last_scrollable_table_row',
		grep {/^[^_]/ or /^__get_ids_/ or $_ eq '__salt'} keys %_REQUEST
	);

	$hidden {$_} = $options -> {$_} foreach (
		'type',
		'action',
	);

	$hidden {__last_query_string} = $_REQUEST{__last_last_query_string};

	my $hiddens_html;

	while (my ($k, $v) = each %hidden) {

		$hiddens_html .= "\n" . dump_tag (input => {

			type  => 'hidden',
			name  => $k,
			value => $v,

		}) if defined $v;

	}

	my $enctype = $data_json =~ /\btype\=[\'\"]?file\b/ ?
		'enctype="multipart/form-data"' : '';

	return <<EOH;

		$$options{title}
		$$options{path}
		$$options{top_toolbar}

		<form name="$$options{name}" action="$_REQUEST{__uri}" method="post" target="invisible" $enctype>
		<input type=hidden name="__suggest" value="" />
		$hiddens_html
		$html
		$$options{toolbar}
		</form>
EOH

}

################################################################################

sub start_page {
}

################################################################################

sub draw_page_just_to_reload_menu {

	my ($_SKIN, $page) = @_;

	my $a = $_JSON -> encode ([$page -> {menu}]);

	my $md5 = Digest::MD5::md5_hex (freeze ($page -> {menu_data}));

	qq {
		var wm = ancestor_window_with_child ('main_menu');
		var a = $a;
		\$(wm.child).html (a[0]);
		wm.window.menu_md5 = '$md5';
	};

}

################################################################################

sub draw__boot_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__script} .= <<EOJS;
;function nope (url, name, options) {
	var w = window;
	if (name == '_self') {
		w.location.href = url;
	}
	else {
		w.open (url, name, options);
	}
}
function _onload () {
	$_REQUEST{__on_load}
}
EOJS

	my $script = dump_tag (script => {}, $_REQUEST {__script}) . "\n";

	return <<EOH;
<html>
	<head>
		<meta http-equiv="X-UA-Compatible" content="IE=edge">

		<title>$$i18n{_page_title}</title>

		<meta name="Generator" content="Eludia ${Eludia::VERSION} / $$SQL_VERSION{string}; parameters are fetched with @{[ ref $apr ]}; gateway_interface is $ENV{GATEWAY_INTERFACE}; @{[$ENV {MOD_PERL} || 'NO mod_perl AT ALL']} is in use">
		<meta http-equiv="Content-Type" content="text/html; charset=$$i18n{_charset}">
		$script
	</head>
	<body onLoad="_onload ()">
		$page->{body}
	</body>
<html>
EOH

}


################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;

	$r -> headers_in -> {'X-Requested-With'} eq 'XMLHttpRequest' && out_json ($page -> {body} || $page -> {content});
	$_REQUEST {type} eq '_boot' && return $_SKIN -> draw__boot_page ($page);

	my $body = $page -> {body};

	my $body_options = {
		bgcolor      => 'white',
		name         => 'body',
		id           => 'body',
	};

	if ($_REQUEST {__refresh_tree}) {

		$_REQUEST {__on_load} .= qq{
			var tree = window.parent.\$('#splitted_tree_window_left');

			if (tree.data ("active") === 2) {
				tree = tree.data ("kendoTreeView");
				tree.dataSource.read();
			} else {
				window.parent.location.reload ();
			}
		};
	}

	if ($_REQUEST {__im_delay}) {

		$_REQUEST {__js_var} -> {__im} = {
			delay =>  $_REQUEST {__im_delay},
			idx   =>  "/i/_mbox/$_USER->{id}.txt",
			url   =>  "/?sid=$_REQUEST{sid}&type=_mbox&action=read",
			timer =>  0,
		};

		$_REQUEST {__on_load} .= '; try {__im_check ()} catch (e) {} ;';

	}

	foreach my $r (@{$page -> {scan2names}}) {
		next if $r -> {off};
		$r -> {data} .= '';
		my $i = 2 * $r -> {alt} + $r -> {ctrl};
		$_REQUEST {__on_load} .= "\nkb_hooks [$i] [$r->{code}] = [handle_hotkey_$r->{type}, ";
		foreach (qw (ctrl alt off type code)) {delete $r -> {$_}}
		$_REQUEST {__on_load} .=  $_JSON -> encode ($r);
		$_REQUEST {__on_load} .= '];';
	}

	$_REQUEST {__head_links}      .= "<META HTTP-EQUIV=Refresh CONTENT='$_REQUEST{__meta_refresh}; URL=@{[create_url()]}&__no_focus=1'>" if $_REQUEST {__meta_refresh};

	$_REQUEST {__js_var} -> {__read_only}              = $_REQUEST {id} ? 0 + $_REQUEST {__read_only} : 1;

	$_REQUEST {__js_var} -> {__last_last_query_string} = 0 + $_REQUEST{__last_query_string};

	$_REQUEST {__js_var} -> {menu_md5}                 = Digest::MD5::md5_hex (freeze ($page -> {menu_data}));

	my $js_var = $_REQUEST {__js_var};

	$_REQUEST {__script}     .= "\nvar $_ = " . $_JSON -> encode ($js_var -> {$_}) . ";\n"                              foreach (keys %$js_var);

	$_REQUEST {__head_links} .= qq{<link  href='$_REQUEST{__static_site}/i/$_.css' type="text/css" rel="stylesheet">}   foreach (@{$_REQUEST {__include_css}});

	$_REQUEST {__head_links} .= "<script src='$_REQUEST{__static_site}/i/${_}.js'>\n</script>"                          foreach (@{$_REQUEST {__include_js}});


	foreach (keys %_REQUEST) {

		/^__on_(\w+)$/ or next;
		$1 eq 'load' and next;

		my $code       = $_REQUEST {$&};

		my $what = $1 eq 'resize' ? 'window' : $1 eq 'beforeunload' ? 'window' : 'document';

		$_REQUEST {__script} .= qq {\n \$($what).bind ('$1', function (event) { $code }) };

	}

	$_REQUEST {__head_links} .= dump_tag (script => {}, $_REQUEST {__script}) . "\n";

	$_REQUEST {__head_links}  = qq {
		<meta http-equiv="X-UA-Compatible" content="IE=edge">

		<title>$$i18n{_page_title}</title>

		<meta name="Generator" content="Eludia ${Eludia::VERSION} / $$SQL_VERSION{string}; parameters are fetched with @{[ ref $apr ]}; gateway_interface is $ENV{GATEWAY_INTERFACE}; @{[$ENV {MOD_PERL} || 'NO mod_perl AT ALL']} is in use">
		<meta http-equiv="Content-Type" content="text/html; charset=$$i18n{_charset}">

		<link href="$_REQUEST{__static_url}/eludia.css" type="text/css" rel="stylesheet" />
		<link href="/i/mint/libs/jQueryUI/jquery-ui.min.css" type="text/css" rel="stylesheet" />
		<link href="/i/mint/libs/SuperTable/supertable.css" type="text/css" rel="stylesheet" />
		<link href="/i/mint/libs/KendoUI/styles/kendo.common.min.css" type="text/css" rel="stylesheet" />
		<link href="/i/mint/libs/KendoUI/styles/kendo.bootstrap.min.css" type="text/css" rel="stylesheet" />

		<script src="/i/mint/libs/require.min.js"></script>
		<script src="/i/mint/libs/KendoUI/js/jquery.min.js"></script>

		<script src="$_REQUEST{__static_url}/navigation.js"></script>
		<script src="$_REQUEST{__static_url}/jQuery.showModalDialog.js" async></script>


	} . $_REQUEST {__head_links};

	my $init_page_options = {
		table_url              => $_SKIN -> table_url (),
		__scrollable_table_row => $_REQUEST {__scrollable_table_row} ||= 0,
		focus                  => !$_REQUEST {__no_focus},
		__focused_input        => $_REQUEST {__focused_input},
		blockui_on_submit      => $preconf -> {core_blockui_on_submit},
		session_timeout        => !$preconf -> {no_keepalive} && $_REQUEST {sid} && 60000 * (($conf -> {session_timeout} ||= 30) - 0.5),
		core_show_dump         => $preconf -> {core_show_dump},
		help_url               => $_REQUEST {__help_url},
	};

	$init_page_options = $_JSON -> encode ($init_page_options);

	my $kendo_modules = join ',',
		qq |"$_REQUEST{__static_url}/i18n_$_REQUEST{lang}.js"|,
		map {qq |"kendo.$_.min"|} keys %{$_REQUEST {__libs} -> {kendo}};


	$_REQUEST {__head_links} .= <<EOJS;
		<script>
			requirejs.config({
				baseUrl: '/i/mint/libs/KendoUI/js',
				shim: {
					'$_REQUEST{__static_url}/i18n_$_REQUEST{lang}.js' : {
						deps: ['cultures/kendo.culture.ru-RU.min']
					},
					'/i/mint/libs/SuperTable/supertable.min.js' : {}
				}
			});
			require([ $kendo_modules ], function () {\$(document).ready (
				function () {
					var options = $init_page_options;
					options.on_load = function () {
						$_REQUEST{__on_load};
					}
					init_page (options);
				})
			});
		</script>
EOJS

	unless ($body =~ /^\s*\<frameset/ism) {
		$body = qq {
			<table id="body_table">
				<tr><td valign=top height=100%>$body</td></tr>
			</table>
			<div style='position:absolute; left:0; top:0; height:100px; width:100px; z-index:100; display:none; pointer-events: none; border: solid #888888 2px;' id="slider" onContextMenu="
				var c = tableSlider.get_cell ();
				if (!c) return;
				var tr = c.parentNode;
				if (!tr) return;
				var h = tr.oncontextmenu;
				if (!h) return;
				return h(event);
			"></div>
			<div style='position:absolute; left:0; top:0; height:4px; width:4px; z-index:101; display:none; border: solid #888888 1px; background-color:white;' id="slider_" ><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=4 height=4 id="slider_"></div>
		};
		$body .= "<iframe name='$_' src='$_REQUEST{__static_url}/0.html' width=0 height=0 application='yes' style='display:none'>\n</iframe>" foreach (@{$_REQUEST{__invisibles}});

		$body  = dump_tag (body => $body_options, $body);
	}

	return qq {<!DOCTYPE html><html><head>$_REQUEST{__head_links}</head>$body</html>};

}

################################################################################

sub table_url {

	my @keep_params = ('id___query', '__last_query_string');

	my $keep_params = join '&', map {"$_=$_REQUEST{$_}"} @keep_params;

	my $table_url = $ENV {QUERY_STRING};

	$table_url =~ s/__last_query_string=-?\d+//;

	$table_url .= '&' . $keep_params . '&__no_json=1';

	return $table_url;
}

################################################################################

sub handle_hotkey_focus {

	my ($r) = @_;

	$r -> {ctrl} += 0;
	$r -> {alt}  += 0;

	<<EOJS
		if (code_alt_ctrl ($$r{code}, $r->{alt}, $r->{ctrl})) {
			document.form.$$r{data}.focus ();
			return blockEvent ();
		}
EOJS

}

################################################################################

sub handle_hotkey_focus_id {

	my ($r) = @_;

	$r -> {ctrl} += 0;
	$r -> {alt}  += 0;

	<<EOJS
		if (code_alt_ctrl ($$r{code}, $r->{alt}, $r->{ctrl})) {
			document.getElementById ('$r->{data}').focus ();
			return blockEvent ();
		}
EOJS

}

################################################################################

sub handle_hotkey_href {

	my ($r) = @_;

	$r -> {ctrl} += 0;
	$r -> {alt}  += 0;

	my $condition =
		$r -> {off}     ? '0' :
		$r -> {confirm} ? 'window.confirm(' . js_escape ($r -> {confirm}) . ')' :
		'1';

#	my $code = !$r -> {href} ? "activate_link_by_id ('$$r{data}')" : "nope ('$$r{href}&__from_table=1&salt=' + Math.random () + '&' + scrollable_rows [scrollable_table_row].id, '_self');";
	my $code = !$r -> {href} ? "activate_link_by_id ('$$r{data}')" : "nope ('$$r{href}&__from_table=1&salt=' + Math.random (), '_self');";

	$condition eq '1' or $code = "if ($condition) {$code}";


	return <<EOJS
		if (code_alt_ctrl ($$r{code}, $r->{alt}, $r->{ctrl})) $code;
EOJS

}

################################################################################

sub lrt_print {

	my $_SKIN = shift;

	open  (OUT, '>>' . $_REQUEST {__lrt_filename}) or die "Can't open $_REQUEST{__lrt_filename}:$!\n";

	flock (OUT, LOCK_EX);

	if ($i18n -> {_charset} ne 'UTF-8') {
		print OUT Encode::decode ('windows-1251', $_) foreach @_
	} else {
		print OUT @_;
	}

	flock (OUT, LOCK_UN);

	close OUT;

	$r -> print (' ' x 100);

}

################################################################################

sub lrt_println {

	my $_SKIN = shift;

	$_SKIN -> lrt_print (@_, '<br>');

}

################################################################################

sub lrt_ok {

	my $_SKIN = shift;

	$_SKIN -> lrt_print ('^:::1:::' . ($_[1] ? $i18n -> {error} : 'OK') . ':::' . ($_[1] || 0) . ':::$');

}

################################################################################

sub lrt_start {

	my $_SKIN = shift;

	$|=1;

	$r -> content_type ("text/html; charset=$i18n->{_charset}");
	$r -> send_http_header ();

	$_REQUEST {__lrt_id} = rand (100000);

	my $mbox_user_path = "i/_mbox/by_user/$_USER->{id}";

	my $mbox_path = "$preconf->{_}->{docroot}$mbox_user_path";

	-d $mbox_path or mkdir $mbox_path;

	foreach my $file (<$mbox_path/lrt_*.txt>) {
		unlink ($file)
				if $file =~ /lrt_(\d+)_/ && $1 != $_REQUEST {sid};
	}

	$_REQUEST {__lrt_filename} = "$mbox_path/lrt_$_REQUEST{sid}_$_REQUEST{__lrt_id}.txt";

	-f $_REQUEST {__lrt_filename} or unlink $_REQUEST {__lrt_filename};

	open OUT, '>' . $_REQUEST {__lrt_filename} or die "Can't open $_REQUEST{__lrt_filename}:$!\n";
	close OUT;


	$r -> print (<<EOH);
		<!doctype html>
		<html>
		<head>
			<link rel="stylesheet" href="$_REQUEST{__static_url}/eludia.css" type="text/css">
			<script src="/i/mint/libs/KendoUI/js/jquery.min.js"></script>
			<script src="$_REQUEST{__static_url}/navigation.js"></script>
			<script src="$_REQUEST{__static_url}/jquery.blockUI.js"></script>

			<script type="text/javascript">

				var lrt_filename = "/$mbox_user_path/lrt_$_REQUEST{sid}_$_REQUEST{__lrt_id}.txt";

				if (window.name == 'invisible') {
					window=parent;
					parent.lrt_start (lrt_filename);
				} else {
					lrt_start (lrt_filename);
				}
			</script>
		</head>
		<body>
		$lrt_bar
		</body>
		</html>
EOH

}

################################################################################

sub lrt_finish {

	my $_SKIN = shift;

	my ($banner, $href, $options) = @_;

# 	if ($options -> {kind} eq 'download') {

# 		$r -> print ($options -> {toolbar});

# 		my $js = q {

# 			var download = document.getElementById ('download');

# 			download.scrollIntoView (true);

# 		};

# 		$js .= user_agent () -> {nt} >= 6 ? '' : ' download.click ();';

# 		$r -> print ("<script>$js</script></body></html>" . (' ' x 4096));

# 	}
	if ($options -> {kind} eq 'link') {

		$_SKIN -> lrt_print ('^:::2:::', qq|<a style="font-size: large;" href="javascript: document.location = '$href'">$banner</a>| . ':::$');

	} else {

		$_SKIN -> lrt_print ('^:::3:::', $banner, ':::' . $href . ':::$');

	}

}


################################################################################

sub draw_tree {

	my ($_SKIN, $node_callback, $list, $options) = @_;

	if ($r -> headers_in -> {'X-Requested-With'} eq 'XMLHttpRequest') {

		foreach my $i (@$list) {

			foreach my $key (keys %{$i -> {__node}}) {
				$i -> {$key} = $i -> {__node} -> {$key};
				$i -> {menu} = $i -> {__menu};
			}

			$i -> {href}   = $options -> {url_base} . $i -> {href};

			delete $i -> {__node};
			delete $i -> {level};
		};

		return;
	}

	$_REQUEST {__libs} -> {kendo} -> {treeview} = 1;
	$_REQUEST {__libs} -> {kendo} -> {splitter} = 1;

	$options -> {name} ||= '_content_iframe';
	$options -> {selected_node} ||= $_REQUEST {selected_node} || 1;
	$options -> {active} ||= 0;

	my $content_div_style = is_ua_mobile ()? "-webkit-overflow-scrolling:touch; overflow: scroll;"
		: "overflow: hidden; ";

	my $html = qq {
		<div id="splitted_tree_window" style="height:100%">
			<div id="splitted_tree_window_left" data-selected-node="$$options{selected_node}">
			</div>
			<div id="splitted_tree_window_right" style="$content_div_style" data-name="$$options{name}">
			</div>
		</div>
	};

	my $js = '';

	if ($options -> {top}) {

		$html = qq {

			<div id="outer_tree_window" style="height:100%">
				<div id="outer_tree_window_top" style="height:$options->{top}->{height}px;">
					<iframe width=100% height=100% src="$options->{top}->{href}" name="_top_iframe" id="__top_iframe" application="yes" noresize scrolling=no>
					</iframe>
				</div>
				<div id="outer_tree_window_bottom" style="height:100%">
					$html
				</div>
			</div>

		};

	}

	if (!$options -> {active}) {

		my %p2n = ();
		my %i2n = ();

		foreach my $i (@$list) {

			my $n = $i -> {__node};

			my $nn = {
				id     => $i -> {id},
				parent => $i -> {parent},
				text   => $n -> {name},
				href   => $options -> {url_base} . $n -> {url},
				menu   => $i -> {__menu},
				clipboard_text => $i -> {clipboard_text},
			};

			$nn -> {imageUrl} = _icon_path ($n -> {icon}) if $n -> {icon};

			push @{$p2n {0 + $i -> {parent}} ||= []}, $nn;

			$i2n {$i -> {id}} = $nn;

		}

		my $id = $options -> {selected_node};

		while (my $nn = $i2n {$id}) {
			$nn -> {expanded} = \1;
			$id = $nn -> {parent};
		}

		foreach my $nn (values %i2n) {

			my $items = $p2n {$nn -> {id}} or next;

			$nn -> {items} = $items;

		}

		my $data = $_JSON -> encode ($p2n {0} ||= []);

		$js .= qq {

			var dataSource = new kendo.data.HierarchicalDataSource({
			    data: $data
			});

		};

	} elsif ($options -> {active} == 2) {

		my @params = @{$options -> {keep_params}} || keys %_REQUEST;
		my $keep_params = join '&', map {"$_=$_REQUEST{$_}"} grep {$_ !~ /^__/i} @params;

		$js .= qq {

			var dataSource = new kendo.data.HierarchicalDataSource({
				transport : {

					read: {
						url      : "/?sid=$_REQUEST{sid}&type=$_REQUEST{type}&__ajax_load=1&$keep_params",
						dataType : "json",
						cache    : false,
					}
				},

				schema: {
					model: {
						id          : '__parent',
						hasChildren : 'cnt_children'
					},

					data : treeview_convert_plain_response,
				}
			});
		};
	}

	$js .= qq {


		\$("#splitted_tree_window_left").data("active", $$options{active}).kendoTreeView({
			dataSource : dataSource,
			expand     : treeview_onexpand,
			collapse   : treeview_oncollapse,
			select: function (e) {
				treeview_onselect_node (e.node);
			}

		});

		if ($$options{active}) {
			\$("#splitted_tree_window_left").data("kendoTreeView").bind("dataBound", treeview_select_node);
		} else {
			treeview_select_node ();
		}
		\$( document ).on( 'contextmenu', "#splitted_tree_window_left li", treeview_oncontextmenu );

	};

	$_REQUEST {__on_load} .= $js;

	return $html;


}

################################################################################

sub draw_node {

	my ($_SKIN, $options, $i) = @_;

	if ($r -> headers_in -> {'X-Requested-With'} eq 'XMLHttpRequest') {

		my $node = {
			id      => $options -> {id},
			text    => $options -> {label},
			parent   => $i -> {parent},
			target   => $i -> {target},
			href     => ($options -> {href_tail} ? '' : $ENV {SCRIPT_URI}) . $options -> {href},
			imageUrl => $options -> {icon}? _icon_path ($options -> {icon}) : undef,
			clipboard_text => $i -> {clipboard_text},
		};

		return $node;

	}


	my $node = {
		id    => $options -> {id},
		pid   => $options -> {parent},
		name  => $options -> {label},
		url   => ($options -> {href_tail} ? '' : $ENV {SCRIPT_URI}) . $options -> {href},
		title => $options -> {title} || $options -> {label},
	};

	map {$node -> {$_} = $options -> {$_} if $options -> {$_}} qw (target icon iconOpen is_checkbox is_radio clipboard_text);

	if ($options -> {title} && $options -> {title} ne $options -> {label}) {
		$node -> {title} = $options -> {title};
	}

	if ($i -> {cnt_children} > 0) {
		$node -> {_hc}  = 1;
		$node -> {_hac} = 0 + $i -> {cnt_actual_children};
		$node -> {_io}  = $i -> {is_open} || ($i -> {id} == $_REQUEST {__parent} ? 1 : 0);
	}
	else {
		$node -> {_hc} = 0;
	}

	$node -> {context_menu} = $i . '' if $i -> {__menu};

	return $node;

}

################################################################################

sub dialog_close {

	my ($_SKIN, $result) = @_;

	my $a = $_JSON -> encode ({
		result => $result,
		alert  => $_REQUEST {__redirect_alert},
	});

	$r -> content_type ("text/html; charset=$i18n->{_charset}");
	$r -> send_http_header ();
	$r -> print (<<EOH);
<html>
	<head>
		<script>

			function load () {
				var a = $a;
				if (a.alert) alert (a.alert);
				var w = window.parent.parent;
				w.returnValue = a.result;
				w.close ();
			}

		</script>
	</head>
	<body onLoad="load ()"></body>
</html>
EOH

}

################################################################################

sub dialog_open {

	my ($_SKIN, $arg, $options) = @_;

	return "javaScript: dialog_open ($options->{id}); setCursor ();";

}

################################################################################

sub draw_suggest_page {

	my ($_SKIN, $data) = @_;

	$_REQUEST {__content_type} ||= 'application/json; charset=windows-1251';

	my $a = $_JSON -> encode ([map {{id => $_ -> {id}, label => $_ -> {label}}} @$data]);

	return $a;

}

################################################################################

sub draw_form_field_article {

	my ($_SKIN, $field, $data) = @_;

	$field -> {value} =~ s{\n}{<br>}gsm;

	return qq{<table width=95% align=center cellpadding=10><tr minheight=200><td>$field->{value}</td></tr></table>};

}

################################################################################

sub draw_page__only_field {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/html; charset=' . $i18n -> {_charset};

	$_REQUEST {__on_load} .= q {;

		window.parent.adjust_kendo_selects();

	};

	return qq{<html><head><script>$_REQUEST{__script}</script></head><body onLoad="$_REQUEST{__on_load}"></body><html>};

}

################################################################################

sub draw_chart {

	my ($_SKIN, $options, $data) = @_;

	my $chart_options = $_JSON -> encode ($options -> {chart});
	$chart_options =~ s/\"([^"]+)\":/$1:/g;

	$options -> {data} -> {data} = $data;
	my $data_source_options = $_JSON -> encode ($options -> {data});
	$data_source_options =~ s/\"([^"]+)\":/$1:/g;

	$options -> {chartArea} -> {height} ||= 400;

	my $html .= <<EOH;
	<table id='$$options{name}' cellspacing=0 cellpadding=0 height="$options->{chartArea}->{height}" width="100%">
		<tr>
			<td>
				<script>

					function series_Click (dialog) {
						var dialog_width = screen.availWidth - (screen.availWidth <= 800 ? 50 : 100);
						var dialog_height = screen.availHeight - (screen.availHeight <= 600 ? 50 : 100);

						dialog.href = dialog.href.replace(/\\#?\\&_salt=[\\d\\.]+\$/, '');

						dialog.href += '&_salt=' + Math.random ();

						var result = window.showModalDialog(
										'$ENV{SCRIPT_URI}/i/_skins/TurboMilk/dialog.html?@{[rand ()]}'
										, dialog
										, 'status:no;help:no;resizable:no' + ';dialogWidth=' + dialog_width + 'px;dialogHeight=' + dialog_height + 'px'
									);
					}

					var DataSource_$$options{name} = new kendo.data.DataSource($data_source_options);

					var chartOptions_$$options{name} = $chart_options;
					chartOptions_$$options{name}.dataSource = DataSource_$$options{name};
					chartOptions_$$options{name}.theme = 'silver';
					chartOptions_$$options{name}.seriesClick = function (e) {
						if (e.dataItem[e.series.field + '_href'] || e.series.href) {
							series_Click (
								{
									'href': (e.dataItem[e.series.field + '_href'] || e.series.href)  + '&salt=' + Math.random() + '&sid=$_REQUEST{sid}',
									'title': e.series.name + ' - (' + e.category + ':' + e.value + ')'
								}
							);
						}
					};

					function createChart_$$options{name}() {
						\$(".chart_$$options{name}").kendoChart(chartOptions_$$options{name});

						var chart_$$options{name} = \$(".chart_$$options{name}").data("kendoChart");

						\$("input[name=svg_text_$$options{name}]").val(chart_$$options{name}.svg());

						\$(window).resize (function() {
							chart_$$options{name}.refresh();
						})
					}

				</script>
				<div class="chart_$$options{name}" style="padding:0px;"></div>
			</td>
		</tr>
	</table>
EOH

	$_REQUEST {__on_load} .= ";setTimeout ('createChart_$$options{name}();', $_REQUEST{__charts_count} * 50);";

	return $html;
}

################################################################################

sub draw_print_chart_images {

	my ($_SKIN, $options) = @_;

	my $html = <<EOH;
	<form
		name="print_chart_images"
		target=invisible
		enctype="$$options{enctype}"
		method="post"
	>
EOH

	$html .= dump_hiddens (

		map {[$_ -> {name} => $_ -> {value}]}

			@{$options -> {keep_params}}

	);

	foreach my $chart_name (@{$_REQUEST {__charts_names}}) {

		$html .= "<input name='svg_text_$chart_name' type='hidden'>";

	}

	$html .= '</form>';
}

################################################################################

sub __adjust_menu_item {

	my ($_SKIN, $type) = @_;

	$type -> {label} =~ s{^\&}{};

	if ($type -> {no_page} || $type -> {items}) {
		$type -> {href} ||= "undefined";
	} else {
		$type -> {href} ||= "/?type=$type->{name}";
	}

	$type -> {id} ||= $type -> {href} eq 'undefined'?
		Digest::MD5::md5_hex ($i18n -> {_charset} eq 'UTF-8' ? Encode::encode ('UTF-8', $type -> {label}) : $type -> {label})
		: $type -> {href};

	$type -> {id} =~ s{[\&\?]?sid\=\d+}{};

}

################################################################################

sub __adjust_form_field_select {

	my ($options) = @_;

	if ($options -> {rows}) {

		$options -> {attributes} -> {multiple} = 1;

		$options -> {attributes} -> {size} = $options -> {rows};

	}

	foreach my $value (@{$options -> {values}}) {

		$value -> {label} = trunc_string ($value -> {label}, $options -> {max_len});

		$value -> {id}    =~ s{\"}{\&quot;}g; #";

	}

	if (defined $options -> {detail}) {

		my $js_detail = js_detail ($options);

		if ($options -> {ds}) {
			$options -> {onChange} .= ";$js_detail";
		} else {
			$options -> {onChange} .= ";var v = this.options[this.selectedIndex].value; if (v && v != -1){$js_detail}";
		}

	}

	return undef;

}

################################################################################

sub __adjust_row_cell_style {

	my ($data, $options) = @_;

	my $a = ($data -> {attributes} ||= {});

	$a -> {colspan} = $data -> {colspan} if $data -> {colspan};
	$a -> {rowspan} = $data -> {rowspan} if $data -> {rowspan};

	$a -> {$_} ||= ($data -> {$_} || $options -> {$_}) foreach (qw (style));

	unless ($a -> {style}) {

		if ($data -> {bgcolor} || $options -> {bgcolor}) {
			$a -> {style} = "background-color: " . ($data -> {bgcolor} || $options -> {bgcolor});
		} else {
			delete $a -> {style};
		}

		$a -> {class} ||= (

			$data    -> {class} ||

			($options -> {class} ||= (

				$options -> {is_total} ? 'row-cell-total' :

				'row-cell'

			))

		);

		$a -> {class} .= '-transparent' if $a -> {bgcolor} && $a -> {class} !~ /-transparent/;

		$a -> {class} .= '-no-scroll' if ($data -> {no_scroll} && $data -> {attributes} -> {class} =~ /row-cell/);

	} elsif ($options -> {bgcolor}) {
		$a -> {style} .= ";background-color: " . $options -> {bgcolor};
	}

}

1;
