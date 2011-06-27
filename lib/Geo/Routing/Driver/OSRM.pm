package Geo::Routing::Driver::OSRM;
use Any::Moose;
use warnings FATAL => "all";
use XML::Simple ();
use Text::Trim;

with qw(Geo::Routing::Role::Driver);

use Geo::Distance::XS;
use HTML::Entities qw(decode_entities);

my $mech = WWW::Mechanize->new;
$mech->get("http://localhost:5000/route&51.2008&-4.06348&51.4664&-3.5414");
my $cont = $mech->content;
#print $cont;

my $xs = XML::Simple->new(
    ForceArray => [ qw(name description) ],
    NumericEscape => 0,
);
my $ref = $xs->XMLin($cont);
my $parsed = parse($ref);
print Dumper $parsed;

sub parse {
    my ($xml_simple_ref) = shift;

    my $document = $xml_simple_ref->{Document};

    # Couldn't find a route
    return unless keys %$document;

    my $Placemark = $document->{Placemark};

    my $last = $Placemark->[-1];
    my $coordinates = $last->{GeometryCollection}->{LineString}->{coordinates};
    my @coordinates = map {
        my $str = $_;
        my ($lon, $lat) = split /,/, $str;
        +{
            longitude => $lon,
            latitude  => $lat,
        }
    } split /\s+/, $coordinates;

    my $distance = 0;

    my $geo = Geo::Distance->new;

    for (my $i = 1; $i < @coordinates; $i++) {
        my $prev_point = $coordinates[$i - 1];
        my $curr_point = $coordinates[$i];

        my ($lon1, $lat1) = @$prev_point{qw(longitude latitude)};
        my ($lon2, $lat2) = @$curr_point{qw(longitude latitude)};

        my $prev_to_curr_distance = $geo->distance(
            kilometer => $lon1, $lat1, $lon2, $lat2,
        );

        $distance += $prev_to_curr_distance;
    }

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

    my $last_instructions = pop @instructions;
    my ($distance, $duration) = $last_instructions->{description} =~ /
        Distance: \s+ ([0-9]+) .*? m
        .*?
        ([0-9]+) \s+ minutes
    /x;

    print STDERR "\n", Dumper($last_instructions), "\n";

    my $return = {
        name         => $last_instructions->{name},
        distance     => $distance,
        duration     => $duration,
        coordinates  => \@coordinates,
        instructions => \@instructions,
    };

    return $return;
}
