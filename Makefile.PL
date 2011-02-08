use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::SiteMap',
    AUTHOR              => q{James Ronan <james@ronanweb.co.uk>},
    VERSION_FROM        => 'lib/Dancer/Plugin/SiteMap.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/SiteMap.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => 0,
	    'Dancer'      => 1.175,
		'XML::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-SiteMap-*' },
);
