use Any::Moose;
use warnings FATAL => "all";
use Test::More;
use Geo::Gosmore;
use Geo::Gosmore::Query;

my $gosmore_pak = $ENV{GOSMORE_PAK};

plan skip_all => "You need a gosmore.pak" unless defined $gosmore_pak and -f $gosmore_pak;
plan 'no_plan';

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
my $route = $gosmore->find_route($query);
my $distance = $route->distance;


isa_ok $query, "Geo::Gosmore::Query";
cmp_ok $query->query_string, 'eq', 'flat=51.5425&flon=-0.111&tlat=51.5614&tlon=-0.0466&fast=1&v=motorcar', "We can generate a string";

isa_ok $gosmore, "Geo::Gosmore";

my $distance_ok = ($distance >= 8 && $distance <= 10);
ok($distance_ok, "Got the distance of <$distance> for a route within London");
