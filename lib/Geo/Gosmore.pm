package Geo::Gosmore;
use Any::Moose;
use warnings FATAL => "all";

=head1 NAME

Geo::Gosmore - Interface to the headless L<gosmore(1)> application

=cut

has gosmore_path => (
    is => 'ro',
    isa => 'Str',
    documentation => "The full path to the gosmore binary",
);

1;

