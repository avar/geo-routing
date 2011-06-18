use Any::Moose;
use warnings FATAL => "all";
use Test::More qw(no_plan);
use Geo::Gosmore::Route;

my $route = Geo::Gosmore::Route->new(
    flat => '51.5425',
    flon => '-0.111',
    tlat => '51.5614',
    tlon => '-0.0466',
    fast => 1,
    v    => 'motorcar',
);

isa_ok $route, "Geo::Gosmore::Route";

warn $route->query_string;

