package Geo::Routing::Driver::Gosmore;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use warnings FATAL => "all";
use autodie qw(:all);
use File::Basename qw(dirname);
use Cwd qw(getcwd);

with qw(Geo::Routing::Role::Driver);

=head1 NAME

Geo::Routing::Driver::Gosmore - Gosmore driver for L<Geo::Routing>

=head1 SYNOPSIS

First install L<gosmore(1)>, e.g. on Debian:

    sudo aptitude install gosmore

Then build a F<gosmore.pak> file:

    wget http://download.geofabrik.de/osm/europe/british_isles.osm.bz2
    # pv(1) is not needed, it just shows you the import progress
    bzcat british_isles.osm.bz2 | pv | gosmore rebuild

Then use this library, with C<gosmore_path> being the full path to
your new F<gosmore.pak>.

    my $gosmore = Geo::Routing->new(
        gosmore_path => $gosmore_path,
    );

    my $query = Geo::Gosmore::Query->new(
        flat => '51.5425',
        flon => '-0.111',
        tlat => '51.5614',
        tlon => '-0.0466',
        fast => 1,
        v    => 'motorcar',
    );

    # Returns false if we can't find a route
    my $route = $gosmore->route($query);
    my $distance = $route->distance;

=head1 DESCRIPTION

Provides an interface to the headless version of the
L<gosmore|http://wiki.openstreetmap.org/wiki/Gosmore> routing
library. When compiled with headless support it provides a simple
interface to do routing. This library just parses its simple output
and provides accessors for it.

We also support accessing the headless L<gosmore(1)> program through a
remote CGI interface.

=head2 ATTRIBUTES

=head2 gosmore_method

Either C<binary> or C<http>. If binary L</gosmore_path> is a path to a
F<gosmore.pak> and we'll invoke L<gosmore(1)> from your C<$PATH>.

If it's C<http> L</gosmore_path> is a URL to an online gosmore router.

=cut

enum GosmoreMethod => qw(
    binary
    http
);

has gosmore_method => (
    is            => 'ro',
    isa           => 'GosmoreMethod',
    required      => 1,
    default       => "binary",
    documentation => "The gosmore method to use. Either 'binary' or 'http'",
);

=head2 gosmore_path

Either a path to a F<gosmore.pak> (see L</gosmore_method>) or a HTTP
URL to a gosmore CGI routing script without query parameters.

=cut

has gosmore_path => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => "The full path to the gosmore.pak file to use, or a HTTP URL with a gosmore instance we can send queries to",
);

has _gosmore_dirname => (
    is            => 'ro',
    isa           => 'Str',
    documentation => "The full path to the directory the gosmore.pak file is in",
    lazy_build    => 1,
);

sub _build__gosmore_dirname {
    my ($self) = @_;

    my $gosmore_path    = $self->gosmore_path;
    my $gosmore_dirname = dirname($gosmore_path);

    return $gosmore_dirname;
}

1;
