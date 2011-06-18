package Geo::Gosmore;
use Any::Moose;
use warnings FATAL => "all";
use autodie qw(:all);
use Geo::Gosmore::Route;
use File::Basename qw(dirname);
use Cwd qw(getcwd);

=encoding utf8

=head1 NAME

Geo::Gosmore - Interface to the headless L<gosmore(1)> routing application

=head1 SYNOPSIS

First install L<gosmore(1)>, e.g. on Debian:

    sudo aptitude install gosmore

Then build a F<gosmore.pak> file:

    wget http://download.geofabrik.de/osm/europe/british_isles.osm.bz2
    # pv(1) is not needed, it just shows you the import progress
    bzcat british_isles.osm.bz2 | pv | gosmore rebuild

Then use this library, with C<$gosmore_pak> being the full path to
your new F<gosmore.pak>.

    my $gosmore = Geo::Gosmore->new(
        gosmore_pak => $gosmore_pak,
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

This is experimental software with an API subject to change.

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

sub route {
    my ($self, $query) = @_;

    my $gosmore_dirname = $self->gosmore_dirname;
    my $query_string = $query->query_string;

    local $ENV{QUERY_STRING} = $query_string;
    local $ENV{LC_NUMERIC} = "en_US";
    my $current_dirname = getcwd();
    chdir $gosmore_dirname;
    open my $gosmore, "gosmore |";
    chdir $current_dirname;

    my @points;
    while (my $line = <$gosmore>) {
        # Skip the HTTP header
        next if $. == 1 || $. == 2;

        $line =~ s/[[:cntrl:]]//g;

        # We couldn't find a route
        return if $line eq 'No route found';

        # We're getting a stream of lat/lon values
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

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Ævar Arnfjörð Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

