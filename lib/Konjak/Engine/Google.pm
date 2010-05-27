package Konjak::Engine::Google;
use strict;
use Data::Dumper;
use Carp;
use base 'Konjak::Engine';
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON 2.0;

sub _API_URI {'http://ajax.googleapis.com/ajax/services/language/translate'};

sub translate {
	my $self = shift;
	my ($original,$language,$text) = @_;
	
	my $has_tags = $text =~ /<.+?>/;
	my @parts = $self->_text_split($has_tags, $text);
	
	my $ua = LWP::UserAgent->new;
	my $query = '';
	my @result = ();
	for (my $i=0; $i<=$#parts; $i++) {
		if ($i >= $#parts or $self->_is_break($has_tags, $parts[$i+1])) {
			$query .= $parts[$i];
			if ($i >= $#parts or length($query)+length($parts[$i+1]) > 3000) {
				my $req = HTTP::Request::Common::POST(
					_API_URI,
					[
						v => '1.0',
						langpair => "$original|$language",
						q => Encode::decode('utf8', $query),
					]
				);
				my $res = $ua->request($req);
				unless ($res->is_success) {
					croak $res->status_line."\n".$res->content;
				}
				my $json = JSON->new->decode($res->content);
				if ($json->{'responseStatus'} ne '200') {
					croak $json->{'responseDetails'};
				}
				my $translated = $json->{'responseData'}->{'translatedText'};
				push @result, $translated;
				$query = '';
			}
		} else {
			$query .= $parts[$i];
		}
	}
	
	return join '', @result;
};

1;
