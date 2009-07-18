use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Net::Rapidshare',
    license           => 'perl',
    dist_author       => 'Mithun Ayachit <m0t0rbr3th@gmail.com>',
    dist_version_from => 'lib/Net/Rapidshare.pm',
    requires          => {
        'Test::More'     => 0,
        'version'        => 0,
        'LWP::UserAgent' => 0,
    },
    add_to_cleanup => ['Net::Rapidshare-*'],
);

$builder->create_build_script();
