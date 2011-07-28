package Geo::Routing::Driver::OSRM::Query;
use Any::Moose;
use warnings FATAL => "all";

with 'Geo::Routing::Role::Query';

sub query_string {
    my ($self, $method) = @_;

    my @atoms = qw(from_latitude from_longitude to_latitude to_longitude);

    my $query_string = "&output=$method&instructions=false&geometry=false&" . join '&', map { $self->$_ } @atoms;

    return $query_string;
}

1;
