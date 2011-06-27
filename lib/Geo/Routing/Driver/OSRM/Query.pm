package Geo::Routing::Driver::OSRM::Query;
use Any::Moose;
use warnings FATAL => "all";

with 'Geo::Routing::Role::Query';

sub query_string {
    my ($self) = @_;

    my @atoms = qw(from_latitude from_longitude to_latitude to_longitude);

    my $query_string = '&' . join '&', map { $self->$_ } @atoms;

    return $query_string;
}

1;
