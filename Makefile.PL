use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Net::Rapidshare',
    AUTHOR        => 'Mithun Ayachit <mithun at cpan dot org>',
    VERSION_FROM  => 'lib/Net/Rapidshare.pm',
    ABSTRACT_FROM => 'lib/Net/Rapidshare.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'     => 0,
        'version'        => 0,
        'LWP::UserAgent' => 0,
'HTML::Entities' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Net::Rapidshare-*' },
);
