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
    $mech->get($url);
    my $content = $mech->content;

    # Parse it
    my $xml_simple = $self->_xml_simple;
    my $xml = $xml_simple->XMLin($content);

    # Do our own parsing
    my $parsed = $self->_parse_data($xml);

    return $parsed;
}

sub _parse_data {
    my ($self, $xml) = @_;

    my $document = $xml->{Document};

    # Couldn't find a route
    return unless keys %$document;

    my $Placemark = $document->{Placemark};

    my $last = $Placemark->[-1];
    my $coordinates = $self->_parse_data_points($last);
    my $instructions = $self->_parse_data_instructions($Placemark);

    my $last_instructions = pop @$instructions;
    my ($distance, $duration) = $last_instructions->{description} =~ /
        Distance: \s+ ([0-9]+) .*? m
        .*?
        ([0-9]+) \s+ minutes
    /x;

    my $return = {
        name         => $last_instructions->{name},
        distance     => $distance,
        duration     => $duration,
        points       => $coordinates,
        instructions => $instructions,
    };

    return $return;
}

sub _parse_data_points {
    my ($self, $last) = @_;

    my $coordinates = $last->{GeometryCollection}->{LineString}->{coordinates};
    my @coordinates = map {
        my $str = $_;
        my ($lon, $lat) = split /,/, $str;
        [ $lat, $lon ];
    } split /\s+/, $coordinates;

    return \@coordinates;
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
