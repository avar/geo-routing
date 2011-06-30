package Geo::Routing::Driver::OSRM;
use Any::Moose;
use warnings FATAL => "all";
use XML::Simple ();
use Text::Trim;
use Geo::Routing::Driver::OSRM::Route;
use HTML::Entities qw(decode_entities);

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

has complex_parsing => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 0,
    documentation => "Should we try to parse out data that we probably don't need?",
);

has _xml_simple => (
    is            => 'ro',
    isa           => 'XML::Simple',
    documentation => "Our instance of XML::Simple",
    lazy_build    => 1,
);

sub _build__xml_simple {
    my ($self) = @_;

    my $xs = XML::Simple->new(
        ForceArray    => [ qw(name description) ],
        NumericEscape => 0,
    );

    return $xs;
}

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

    my $parsed;
    if ($self->complex_parsing) {
        # Parse it
        my $xml_simple = $self->_xml_simple;
        my $xml = $xml_simple->XMLin($content);

        # Do our own parsing
        $parsed = $self->_parse_data($xml);
        return unless $parsed;
    } else {
        if ($content =~ m[<Document>\s*</Document>]s) {
            return;
        }

        my ($coordinates_str) = $content =~ m[<coordinates>([^<]+)</coordinates>]s;
        my $coordinates = $self->_parse_data_points($coordinates_str);

        my ($distance, $duration) = $content =~ /
            Distance: \s+ ([0-9]+) .*? m
            .*?
            ([0-9]+) \s+ minutes
        /x;

        $parsed = {
            distance     => ($distance / 1000),
            travel_time  => ($duration * 60),
            points       => $coordinates,
        };
    }

    my $route = Geo::Routing::Driver::OSRM::Route->new(%$parsed);

    return $route;
}

sub _parse_data {
    my ($self, $xml) = @_;

    my $document = $xml->{Document};

    # Couldn't find a route
    return unless keys %$document;

    my $Placemark = $document->{Placemark};

    my $last = $Placemark->[-1];
    my $coordinates_str = $last->{GeometryCollection}->{LineString}->{coordinates};
    my $coordinates = $self->_parse_data_points($coordinates_str);
    my $instructions = $self->_parse_data_instructions($Placemark);

    my $last_instructions = pop @$instructions;
    my ($distance, $duration) = $self->_parse_distance_and_duration_from_description($last_instructions->{description});

    my $return = {
        name         => $last_instructions->{name},
        distance     => ($distance / 1000),
        travel_time  => ($duration * 60),
        points       => $coordinates,
        instructions => $instructions,
    };

    return $return;
}

sub _parse_data_points {
    my ($self, $coordinates_str) = @_;

    my @coordinates = map {
        my $str = $_;
        my ($lon, $lat) = split /,/, $str;
        [ $lat, $lon ];
    } split /\s+/, $coordinates_str;

    return \@coordinates;
}

sub _parse_distance_and_duration_from_description {
    my ($self, $description) = @_;

    my ($distance, $duration) = $description =~ /
        Distance: \s+ ([0-9]+) .*? m
        .*?
        ([0-9]+) \s+ minutes
    /x;

    return ($distance, $duration);
}

sub _parse_data_instructions {
    my ($self, $Placemark) = @_;

    my @instructions;
    for (my $i = 0; $i < @$Placemark; $i++) {
        my $node = $Placemark->[$i];
        my $point;
        for my $thing (qw(name description)) {
            if (exists $node->{$thing}) {
                my $trimmed = trim($node->{$thing}->[0]);
                my $escaped = decode_entities($trimmed);
                utf8::decode($escaped);
                $point->{$thing} = $escaped;
            }
        }
        push @instructions => $point;
    }

    return \@instructions;
}

1;
