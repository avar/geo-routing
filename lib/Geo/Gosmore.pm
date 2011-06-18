package Geo::Gosmore;
use Any::Moose;
use warnings FATAL => "all";
use autodie qw(:all);
use Geo::Gosmore::Route;
use File::Basename qw(dirname);
use Cwd qw(getcwd);

=head1 NAME

Geo::Gosmore - Interface to the headless L<gosmore(1)>

=cut

has gosmore_pak => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => "The full path to the gosmore.pak file",
);

has gosmore_dirname => (
    is            => 'ro',
    isa           => 'Str',
    documentation => "The full path to the directory the gosmore.pak file is in",
    lazy_build    => 1,
);

sub _build_gosmore_dirname {
    my ($self) = @_;

    my $gosmore_pak     = $self->gosmore_pak;
    my $gosmore_dirname = dirname($gosmore_pak);

    return $gosmore_dirname;
}

sub find_route {
    my ($self, $query) = @_;

    my $gosmore_dirname = $self->gosmore_dirname;
    my $query_string = $query->query_string;

    local $ENV{QUERY_STRING} = $query_string;
    my $current_dirname = getcwd();
    chdir $gosmore_dirname;
    open my $gosmore, "gosmore |";
    chdir $current_dirname;

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

