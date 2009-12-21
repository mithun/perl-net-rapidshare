use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Net::Rapidshare',
    license           => 'perl',
    dist_author       => 'Mithun Ayachit <mithun at cpan dot org>',
    dist_version_from => 'lib/Net/Rapidshare.pm',
    requires          => {
        'Test::More'     => 0,
        'LWP::UserAgent' => 0,
        'HTML::Entities' => 0,
    },
    add_to_cleanup => ['Net::Rapidshare-*'],
);

$builder->create_build_script();
