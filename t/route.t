use Any::Moose;
use warnings FATAL => "all";
use Test::More 'no_plan';

use_ok 'Geo::Gosmore';
use_ok 'Geo::Gosmore::Query';

my @from_to = (
    {
        args => {
            flat => '51.5425',
            flon => '-0.111',
            tlat => '51.5614',
            tlon => '-0.0466',
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
            flat => '51.5425',
            flon => '-0.111',
            tlat => '52.325',
            tlon => '1.317',
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
            flat => '52.75929',
            flon => '-4.7844',
            tlat => '52.7996',
            tlon => '-4.7368',
        },
        no_route => 1,
    }
);

my %gosmore = (
    binary => {
        args => {
            gosmore_path => $ENV{GOSMORE_PAK},
        },
        run_if => sub {
            my $gosmore_pak = $ENV{GOSMORE_PAK};
            defined $gosmore_pak and -f $gosmore_pak;
        },
    },
    http => {
        args => {
            gosmore_method => 'http',
            gosmore_path   => $ENV{GOSMORE_HTTP_PATH},
        },
        run_if => sub { $ENV{GOSMORE_HTTP_PATH} },
    }
);

for my $test (sort keys %gosmore) {
    my $should_run = $gosmore{$test}->{run_if}->();
    unless ($should_run) {
        diag "Skipping $test test";
        next;
    }

    my %args = %{ $gosmore{$test}->{args} };
    my $gosmore = Geo::Gosmore->new(%args);

    isa_ok $gosmore, "Geo::Gosmore";

  ROUTE: for my $from_to (@from_to) {
        my $args = $from_to->{args};
        my ($flat, $flon, $tlat, $tlon) = @$args{qw(flat flon tlat tlon)};
        my $query = Geo::Gosmore::Query->new(
            flat => $flat,
            flon => $flon,
            tlat => $tlat,
            tlon => $tlon,
            fast => 1,
            v    => 'motorcar',
        );
        isa_ok $query, "Geo::Gosmore::Query";
        my $qs = "flat=${flat}&flon=${flon}&tlat=${tlat}&tlon=${tlon}&fast=1&v=motorcar";
        cmp_ok $query->query_string, 'eq', $qs, qq[QUERY_STRING="$qs" gosmore];

        my $route = $gosmore->route($query);

        if ($from_to->{no_route}) {
            ok(!$route, "We can't find a route");
            next ROUTE;
        }


        for my $value (qw(distance travel_time)) {
            if (my $callback = $from_to->{"${value}_ok"}) {
                my $got = $route->$value;
                my $got_ok = $callback->($got);
                ok($got_ok, "Got the $value of <$got> for a route, which was within bounds");
            }
        }
    }
}
