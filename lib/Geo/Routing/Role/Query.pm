package Geo::Routing::Role::Query;
use Any::Moose '::Role';
use warnings FATAL => "all";
use namespace::clean -except => "meta";

has from_latitude => (
    is            => 'ro',
    isa           => 'Num',
    required      => 1,
    documentation => '',
);

has from_longitude => (
    is            => 'ro',
    isa           => 'Num',
    required      => 1,
    documentation => '',
);

has to_latitude => (
    is            => 'ro',
    isa           => 'Num',
    required      => 1,
    documentation => '',
);

has to_longitude => (
    is            => 'ro',
    isa           => 'Num',
    required      => 1,
    documentation => '',
);

1;
