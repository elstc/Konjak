package Konjak::Engine::Bing;
use strict;
use Data::Dumper;
use Carp;
use base 'Konjak::Engine';
use LWP::UserAgent;
use HTTP::Request::Common;
use URI;

sub _API_URI {'http://api.microsofttranslator.com/V1/Http.svc/Translate'};

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
			if ($i >= $#parts or length($query)+length($parts[$i+1]) > 6000) {
				my $uri = URI->new(_API_URI);
				$uri->query_form(
					appid => $self->setting('engine_bing_appid'),
					from => $original,
					to => $language,
				);
				my $req = HTTP::Request::Common::POST(
					$uri->as_string,
					'content' => $query,
					'content-type' => 'text/plain',
				);
				my $res = $ua->request($req);
				unless ($res->is_success) {
					croak $res->status_line."\n".$res->content;
				}
				my $translated = $res->content;
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
