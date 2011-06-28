package Geo::Routing::Driver::OSRM::Route;
use Any::Moose;
use warnings FATAL => "all";

with 'Geo::Routing::Role::Route';

sub _build_travel_time { die "This should already be set implicitly" }

1;
