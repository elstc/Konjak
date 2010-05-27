package Konjak::Cache;
use strict;
use base 'MT::Object';

__PACKAGE__->install_properties({
	column_defs => {
		'id'			=> 'integer not null auto_increment',
		'blog_id'		=> 'integer not null',
		'entry_id'		=> 'integer not null',
		'page_id'		=> 'integer not null',
		'language'		=> 'string(5) not null',
		'checksum'		=> 'string(64) not null',
		'translated'	=> 'text',
		'using'			=> 'boolean not null',
	},
	audit => 1,
	indexes => {
		blog_id => 1,
		entry_id => 1,
		page_id => 1,
		blog_entry_language_checksum => {
			columns => ['blog_id', 'entry_id', 'language', 'checksum'],
			unique => 1,
		},
		entry_using => {
			columns => ['entry_id', 'using'],
		},
	},
	child_of => 'MT::Entry',
	datasource => 'konjak_cache',
	primary_key => 'id',
});

1;
