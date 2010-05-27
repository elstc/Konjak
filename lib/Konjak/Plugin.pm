package Konjak::Plugin;
use strict;
use Data::Dumper;
use Carp;
use MT 4;
use MT::Util;
use Encode;
use UNIVERSAL::require;
use Konjak::Cache;

sub tag_block_translate {
	my ($ctx,$args,$cond) = @_;
	
	return unless defined(my $blog = MT->instance->blog);
	my $entry = $ctx->stash('entry');
	my $entry_id = defined($entry) ? $entry->id : 0;
	
	my $builder = $ctx->stash('builder');
	my $tokens  = $ctx->stash('tokens');
	defined(my $text = $builder->build($ctx,$tokens,$cond)) or return $ctx->error($builder->errstr);
	
	return _translate($blog->id, $entry_id, $text, $args->{language});
}

sub tag_modifire_translate {
	my ($text, $val, $ctx) = @_;
	
	return unless defined(my $blog = MT->instance->blog);
	my $entry = $ctx->stash('entry');
	my $entry_id = defined($entry) ? $entry->id : 0;
	
	return _translate($blog->id, $entry_id, $text, $val);
}

sub callback_cms_post_save_entry {
	my ($cb, $app, $entry, $original) = @_;
	my @caches = Konjak::Cache->load({blog_id=>$app->blog->id, entry_id=>$entry->id});
	foreach my $cache (@caches) {
		$cache->using(0);
		$cache->save;
	}
	return undef;
}

sub callback_cms_post_delete_entry {
	my ($cb, $app, $obj) = @_;
	Konjak::Cache->remove({entry_id=>$obj->id});
	return undef;
}

sub callback_post_build {
	my ($cb, $obj) = @_;
	my $blog = MT::instance->blog;
	Konjak::Cache->remove({blog_id=>$blog->id, using=>0});
	return undef;
}

sub method_remove_cache {
	my ($app) = @_;
	my $blog_id = $app->blog->id;
	Konjak::Cache->remove({blog_id=>$blog_id});
	$app->redirect(
		$app->uri(
			mode => 'cfg_plugins',
			args => {blog_id => $blog_id}
		)
	);
}


sub _translate {
	my ($blog_id, $entry_id, $text, $language) = @_;
	$text = (5 <= $MT::VERSION) ? Encode::encode('utf8', $text) : $text;
	
	my $translated = '';
	my $checksum = MT::Util::perl_sha1_digest_hex($text);
	my $cache = _load_cache($blog_id, $entry_id, $language, $checksum);
	if (defined($cache)) {
		$cache->using(1);
		$cache->save;
		return $cache->translated;
	}
	my $translated = _get_translated_text($text, $language);
	_store_cache($blog_id, $entry_id, $language, $checksum, $translated);
	
	return (5 <= $MT::VERSION) ? Encode::decode('utf8', $translated) : $translated;
}

sub _get_settings {
	my $plugin = MT->component("Konjak");
	my $blog_id = MT->instance->blog->id;
	$plugin->get_config_hash('blog:'. $blog_id);
}

sub _load_cache {
	my ($blog_id, $entry_id, $language, $checksum) = @_;
	my $cache = Konjak::Cache->load({blog_id=>$blog_id, entry_id=>$entry_id, language=>$language, checksum=>$checksum});
	return $cache;
}

sub _store_cache {
	my ($blog_id, $entry_id, $language, $checksum, $translated) = @_;
	my $cache = Konjak::Cache->new;
	$cache->blog_id($blog_id);
	$cache->entry_id($entry_id);
	$cache->page_id($entry_id);
	$cache->language($language);
	$cache->checksum($checksum);
	$cache->translated(Encode::decode('utf8',$translated));
	$cache->using(1);
	$cache->save;
}

sub _load_engine_class {
	(my $module = shift) =~ s/^(.)/uc($1)/e;
	my $class = 'Konjak::Engine::'. $module;
	$class->require or die $@;
	return $class;
}

sub _get_translated_text {
	my ($text, $language) = @_;
	my $settings = _get_settings();
	my $engine = $settings->{translation_engine};
	my $translator = _load_engine_class($engine)->new;
	foreach my $key (keys %{$settings}) {
		$translator->setting($key, $settings->{$key}) if $key =~ /^engine\_$engine\_/;
	}
	my $translated = $translator->translate($settings->{original_language}, $language, $text);
	return $translated;
}

1;
