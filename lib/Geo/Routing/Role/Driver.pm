package Geo::Routing::Role::Driver;
use Any::Moose '::Role';
use warnings FATAL => "all";
use namespace::clean -except => "meta";

use WWW::Mechanize;

has _mech => (
    is            => 'ro',
    isa           => 'WWW::Mechanize',
    documentation => "Our instance of WWW::Mechanize",
    lazy_build    => 1,
);

sub _build__mech {
    my ($self) = @_;

    WWW::Mechanize->new(
        user_agent => __PACKAGE__,
    );
}

1;
