package Geo::Routing;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use warnings FATAL => "all";
use Data::Dumper;
use Class::Load qw(load_class);

=encoding utf8

=head1 NAME

Geo::Routing - Interface to the L<gosmore(1)> and L<OSRM|http://routed.sourceforge.net/> routing libraries

=head1 ATTRIBUTES

=cut

=head2 driver

What driver should we be using to do the routing?

=cut

enum GeoRoutingDrivers => qw(
    OSRM
    Gosmore
);

has driver => (
    is            => 'ro',
    isa           => 'GeoRoutingDrivers',
    required      => 1,
    documentation => '',
);

=head2 driver_args

ArrayRef of arguments to pass to the driver.

=cut

has driver_args => (
    is => 'ro',
    isa => 'HashRef',
);

has _driver_object => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build__driver_object {
    my ($self) = @_;

    print STDERR Dumper $self;
    my $driver        = $self->driver;
    my $module        = "Geo::Routing::Driver::$driver";
    load_class($module);
    my %args          = (
        Module => $module,
        Args   => $self->driver_args,
    );
    my $driver_object = $module->new(%args);
    print STDERR Dumper \%args;

    return $driver_object;
}

=head1 METHODS

=cut

=head2 route

Find a route based on the L<attributes|/ATTRIBUTES> you've passed
in. Takes a L<Geo::Gosmore::Query> object with your query, returns a
L<Geo::Gosmore::Route> object.

=cut

sub query {
    my ($self, %query) = @_;

    $self->_driver_object->query(%query);

    return;
}

sub route {
    my ($self, $query) = @_;

    my $lines = $self->_get_normalized_routing_lines($query);

    my @points;
    for my $line (@$lines) {
        # We couldn't find a route
        return if $line eq 'No route found';

        print STDERR "$line\n" if $ENV{DEBUG};

        # We're getting a stream of lat/lon values
        next unless $line =~ /^[0-9]/;

        my ($lat, $lon, $junction_type, $style, $remaining_time, $name) = split /,/, $line;
        push @points => [ $lat, $lon, $junction_type, $style, $remaining_time, $name ];
    }

    my $route = Geo::Gosmore::Route->new(
        points => \@points,
    );

    return $route;
}

sub _get_normalized_routing_lines {
    my ($self, $query) = @_;

    my $method = $self->gosmore_method;
    my @lines;

    my $query_string = $query->query_string;
    if ($method eq 'binary') {
        my $gosmore_dirname = $self->_gosmore_dirname;

        local $ENV{QUERY_STRING} = $query_string;
        local $ENV{LC_NUMERIC} = "en_US";
        my $current_dirname = getcwd();
        chdir $gosmore_dirname;
        open my $gosmore, "gosmore |";
        chdir $current_dirname;

        while (my $line = <$gosmore>) {
            # Skip the HTTP header
            next if $. == 1 || $. == 2;

            $line =~ s/[[:cntrl:]]//g;

            push @lines => $line;
        }

    } elsif ($method eq 'http') {
        my $mech = $self->_mech;
        my $url = sprintf "%s?%s", $self->gosmore_path, $query_string;
        $mech->get($url);
        my $content = $mech->content;
        use Data::Dumper;
        @lines = map {
            s/[[:cntrl:]]//g;
            $_;
        } split /\n/, $content;
    }

    return \@lines;
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Ævar Arnfjörð Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

