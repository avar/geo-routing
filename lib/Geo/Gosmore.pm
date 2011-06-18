package Geo::Gosmore;
use Any::Moose;
use warnings FATAL => "all";
use autodie qw(:all);

=head1 NAME

Geo::Gosmore - Interface to the headless L<gosmore(1)>

=cut

has gosmore_path => (
    is => 'ro',
    isa => 'Str',
    documentation => "The full path to the gosmore binary",
);

has route => (
    is => 'ro',
    isa => "Geo::Gosmore::Route",
);

sub route {
    my ($self, $route) = @_;

    chdir "/home/avar/g/gosmore";

    my $query_string = $self->route;

    warn $query_string;

    open my $gosmore, qq[QUERY_STRING="$query_string" ./gosmore];

    while (my $line = <$gosmore>) {
        warn $line;
    }

    return;

}

1;

