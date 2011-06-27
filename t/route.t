use Any::Moose;
use warnings FATAL => "all";
use Test::More 'no_plan';
use Data::Dumper;

use_ok 'Geo::Routing';

my @from_to = (
    {
        args => {
            from_latitude  => '51.5425',
            from_longitude => '-0.111',
            to_latitude    => '51.5614',
            to_longitude    => '-0.0466',
        },
        distance_ok => sub {
            my ($distance) = @_;

            ($distance >= 8 && $distance <= 10);
        },
        travel_time_ok => sub {
            my ($travel_time) = @_;

            ($travel_time >= 300 && $travel_time <= 400);
        },
    },
    {
        args => {
            from_latitude  => '51.5425',
            from_longitude => '-0.111',
            to_latitude    => '52.325',
            to_longitude   => '1.317',
        },
        distance_ok => sub {
            my ($distance) = @_;

            ($distance >= 200 && $distance <= 230);
        },
        travel_time_ok => sub {
            my ($travel_time) = @_;

            ($travel_time >= 5000 && $travel_time <= 7000);
        },
    },
    {
        args => {
            from_latitude  => '52.75929',
            from_longitude => '-4.7844',
            to_latitude    => '52.7996',
            to_longitude   => '-4.7368',
        },
        no_route => 1,
    }
);

my %driver = (
    Gosmore => [
        {
            args => {
                gosmore_path => $ENV{GOSMORE_PAK},
                gosmore_method => 'binary',
            },
            run_if => sub {
                my $gosmore_pak = $ENV{GOSMORE_PAK};
                defined $gosmore_pak and -f $gosmore_pak;
            },
        },
        {
            args => {
                gosmore_method => 'http',
                gosmore_path   => $ENV{GOSMORE_HTTP_PATH},
            },
            run_if => sub { $ENV{GOSMORE_HTTP_PATH} },
        }
    ],
    OSRM => [
        {
            args => {
                osrm_path => $ENV{OSRM_HTTP_PATH},
            },
            run_if => sub { $ENV{OSRM_HTTP_PATH} },
        }
    ],
);

for my $driver (sort keys %driver) {
    ok 1, "Testing the $driver driver";
    for my $test (@{ $driver{$driver} }) {
        my $should_run = $test->{run_if}->();
        unless ($should_run) {
            diag "Skipping a $driver test";
            next;
        }

        my %args = (
            driver      => $driver,
            driver_args => $test->{args},
        );
        my $routing = Geo::Routing->new(%args);


        isa_ok $routing, "Geo::Routing";

      ROUTE: for my $from_to (@from_to) {
            my $args = $from_to->{args};
            my ($flat, $flon, $tlat, $tlon) = @$args{qw(from_latitude from_longitude to_latitude to_longitude)};
            my $query = $routing->query(
                from_latitude  => $flat,
                from_longitude => $flon,
                to_latitude    => $tlat,
                to_longitude   => $tlon,
                ($driver eq 'Gosmore'
                 ? (
                     fast      => 1,
                     v         => 'motorcar'
                 )
                 : ()),
            );
            isa_ok $query, "Geo::Routing::Driver::${driver}::Query";
            if ($driver eq 'Gosmore') {
                my $qs = "flat=${flat}&flon=${flon}&tlat=${tlat}&tlon=${tlon}&fast=1&v=motorcar";
                cmp_ok $query->query_string, 'eq', $qs, qq[QUERY_STRING="$qs" gosmore];
            } elsif ($driver eq 'OSRM') {
                my $qs = "&${flat}&${flon}&${tlat}&${tlon}";
                cmp_ok $query->query_string, 'eq', $qs, qq[http://localhost:5000/route$qs];
            }

            my $route = $routing->route($query);

            if ($from_to->{no_route}) {
                ok(!$route, "We can't find a route");
                next ROUTE;
            }

            CHECK_VALUE: for my $value (qw(distance travel_time)) {
                unless ($route->can($value)) {
                    ok(1, "The driver $driver doesn't have a $value method, skipping");
                    next CHECK_VALUE;
                }
                if (my $callback = $from_to->{"${value}_ok"}) {
                    my $got = $route->$value;
                    my $got_ok = $callback->($got);
                    ok($got_ok, "$driver: Got the $value of <$got> for a route, which was within bounds");
                }
            }
        }
    }
}
