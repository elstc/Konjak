package Konjak::Engine;
use strict;
use Carp;

sub new {
	my $class = shift;
	my $self = {};
	$class = bless $self, $class;
	$self->initialize;
	return $self;
};

sub initialize {
	my $self = shift;
	$self->{'_SETTINGS'} = {};
}

sub setting {
	my $self = shift;
	my ($key, $value) = @_;
	if (defined($value)) {
		$self->{'_SETTINGS'}->{$key} = $value;
	} else {
		return $self->{'_SETTINGS'}->{$key};
	}
}

sub translate {
	confess 'not implemented';
};

sub _is_break {
	my $self = shift;
	my ($has_tags, $part) = @_;
	if ($has_tags) {
		return 1 if $part =~ /^<\/?(br|address|blockquote|dd|div|dl|fieldset|form|h1|h2|h3|h4|h5|h6|hr|li|noframes|ol|p|pre|table|thead|tbody|tfoot|tr|td|ul)/i;
	} else {
		return 1 if $part =~ /^(\x0d\x0a|\x0d|\x0a)/;
	}
	return 0;
};

sub _text_split {
	my $self = shift;
	my ($has_tags, $text) = @_;
	my @parts = ();
	
	my $fnc = sub {
		my ($p, $array) = @_;
		push @$array, $p if $p ne '';
		return '';
	};
	
	if ($has_tags) {
		$text =~ s/([^<]*|<.+?>)/$fnc->($1,\@parts)/eg;
	} else {
		$text =~ s/(\x0d\x0a|\x0d|\x0a|.*)/$fnc->($1,\@parts)/eg;
	}
	
	return @parts;
};

1;
