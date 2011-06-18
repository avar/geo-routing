package Geo::Gosmore;
use Any::Moose;
use warnings FATAL => "all";
use autodie qw(:all);
use Geo::Gosmore::Route;

=head1 NAME

Geo::Gosmore - Interface to the headless L<gosmore(1)>

=cut

has gosmore_path => (
    is => 'ro',
    isa => 'Str',
    documentation => "The full path to the gosmore binary",
);

sub find_route {
    my ($self, $query) = @_;

    chdir "/home/avar/g/gosmore";

    my $query_string = $query->query_string;

    warn $query_string;

    local $ENV{QUERY_STRING} = $query_string;
    open my $gosmore, "./gosmore |";

    my @points;
    while (my $line = <$gosmore>) {
        $line =~ s/[[:cntrl:]]//g;
        next unless $line =~ /^[0-9]/;

        my ($lat, $lon, undef, $style, undef, $name) = split /,/, $line;
        push @points => [ $lat, $lon, undef, $style, undef, $name ];
    }

    my $route = Geo::Gosmore::Route->new(
        points => \@points,
    );

    return $route;
}

1;

