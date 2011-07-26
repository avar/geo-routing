package Geo::Routing::Driver::OSRM;
use Any::Moose;
use warnings FATAL => "all";
use Text::Trim;
use Geo::Routing::Driver::OSRM::Route;
use JSON::XS qw(decode_json);

with qw(Geo::Routing::Role::Driver);

has osrm_path => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => "The base URL of a HTTP with OSRM instance we can send queries to",
);

has use_curl => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 1,
    documentation => "Should we shell out to curl(1) to get http content?",
);

sub route {
    my ($self, $query) = @_;

    # Get the XML content
    my $query_string = $query->query_string;
    my $mech = $self->_mech;
    my $url = sprintf "%s%s", $self->osrm_path, $query_string;
    my $content;
    if ($self->use_curl) {
        chomp($content = qx[curl -s '$url']);
    } else {
        $mech->get($url);
        $content = $mech->content;
    }

    my $json = decode_json($content);

    # No route found
    return if $json->{status} eq '207';

    my $route_summary = $json->{route_summary};
    my ($distance, $duration) = @$route_summary{qw(total_distance total_time)};
    my $parsed = {
        distance     => ($distance / 1000),
        travel_time  => ($duration),
        points       => $json->{route_geometry},
    };

    my $route = Geo::Routing::Driver::OSRM::Route->new(%$parsed);

    return $route;
}

1;
