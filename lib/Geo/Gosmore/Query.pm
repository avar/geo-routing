package Geo::Gosmore::Query;
use Any::Moose;
use warnings FATAL => "all";

has flat => (
    is            => 'ro',
    isa           => 'Num',
    required      => 1,
    documentation => '',
);

has flon => (
    is            => 'ro',
    isa           => 'Num',
    required      => 1,
    documentation => '',
);

has tlat => (
    is            => 'ro',
    isa           => 'Num',
    required      => 1,
    documentation => '',
);

has tlon => (
    is            => 'ro',
    isa           => 'Num',
    required      => 1,
    documentation => '',
);

has fast => (
    is            => 'ro',
    isa           => 'Int',
    required      => 1,
    documentation => '',
);


has v => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => '',
);

sub query_string {
    my ($self) = @_;

    my @atoms = qw(flat flon tlat tlon fast v);

    my $query_string = join '&', map {
        sprintf "%s=%s", $_, $self->$_;
    } grep {
        defined $self->$_;
    } @atoms;

    return $query_string;
}

1;
