package Dancer::Plugin::SiteMap;

use strict;
use Dancer qw(:syntax);
use Dancer::Plugin;

use XML::Simple;

=head1 NAME

Dancer::Plugin::SiteMap - Automated site map for the Dancer web framework.

=head1 VERSION

Version 0.10

=cut

our $VERSION     = '0.10';
my  $OMIT_ROUTES = [];

# Add syntactic sugar for omitting routes.
register 'sitemap_ignore' => sub {
    $Dancer::Plugin::SiteMap::OMIT_ROUTES = \@_;
};

# Add this plugin to Dancer, both Dancer 1 and Dancer 2 :-)
register_plugin( for_versions => [ qw( 1 2 ) ] );


# Add the routes for both the XML sitemap and the standalone one.
get '/sitemap.xml' => sub {
    _xml_sitemap();
};

get '/sitemap' => sub {
    _html_sitemap();
};

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::SiteMap;

Yup, its that simple. Optionally you can omit routes:

    sitemap_ignore ('ignore/this/route', 'orthese/.*');

=head1 DESCRIPTION

B<This plugin now supports Dancer 1 and 2!>

Plugin module for the Dancer web framwork that automagically adds sitemap
routes to the webapp. Currently adds /sitemap and /sitemap.xml where the
former is a basic HTML list and the latter is an XML document of URLS.

Currently it only adds staticly defined routes for the GET method.

Using the module is literally that simple... 'use' it and your app will
have a site map.

The HTML site map list can be styled throught the CSS class 'sitemap'

Added additional functionality in 0.06 as follows:

Firstly, fixed the route selector so the sitemap doesn't show the "or not"
operator ('?'), any route defined with a ':variable' in the path or a pure
regexp as thats just dirty.

More importantly, I came across the requirement to not have a few admin pages
listed in the sitemap, so I've added the ability to tell the plugin to ignore
certain routes via the sitemap_ignore keyword.

=cut

# The action handler for the automagic /sitemap route. Uses the list of
# URLs from _retreive_get_urls and outputs a basic HTML template to the
# browser using the standard layout if one is defined.
sub _html_sitemap {
    my @urls          = _retreive_get_urls();

    my $content       = qq[ <h2> Site Map </h2>\n<ul class="sitemap">\n ];
    for my $url (@urls) {
        $content .= qq[ <li><a href="$url">$url</a></li>\n ];
    }
    $content .= qq[ </ul>\n ];

    return engine('template')->apply_layout($content);
};


# The action handler for the automagic /sitemap.xml route. Uses the list of
# URLs from _retreive_get_urls and outputs an XML document to the browser.
sub _xml_sitemap {
    my @urls = _retreive_get_urls();
    my @sitemap_urls;

    # add the "loc" key to each url so XML::Simple creates <loc></loc> tags.
    for my $url (@urls) {
        my $uri = uri_for($url);
        push @sitemap_urls, { loc => [ "$uri" ] }; # $uri has to be stringified
    }

    # create a hash for XML::Simple to turn into XML.
    my %urlset = (
        xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9',
        url   => \@sitemap_urls
    );

    my $xs  = new XML::Simple( KeepRoot   => 1,
                               ForceArray => 0,
                               KeyAttr    => {urlset => 'xmlns'},
                               XMLDecl    => '<?xml version="1.0" encoding="UTF-8"?>' );
    my $xml = $xs->XMLout( { urlset => \%urlset } );

    content_type "text/xml";
    return $xml;
};


# Obtains the list of URLs from Dancers Route Registry.
sub _retreive_get_urls {

    my $version = (exists &dancer_version) ? int( dancer_version() ) : 1;
    my @apps    = ($version == 2) ? @{ runner->server->apps }
                                  : Dancer::App->applications;

    my ($route, @urls);
    for my $app ( @apps ) {
        my $routes = ($version == 2) ? $app->routes
                                     : $app->{registry}->{routes};

        # push the static get routes into an array.
        get_route:
        for my $get_route ( @{ $routes->{get} } ) {
            my $pattern = ($version == 2) ? $get_route->spec_route
                                          : $get_route->{pattern};

            if (ref($pattern) !~ m/HASH/i) {

                # If the pattern is a true comprehensive regexp or the route
                # has a :variable element to it, then omit it. Dancer 2 also
                # has /** entries - we'll dump them too.
                next get_route if ($pattern =~ m/[()[\]|]|:\w/);
                next get_route if ($pattern =~ m{/\*\*});

                # If there is a wildcard modifier, then drop it and have the
                # full route.
                $pattern =~ s/\?//g;

                # Other than that, its cool to be added.
                push (@urls, $pattern)
                    if ! grep { $pattern =~ m/$_/i }
                              @$Dancer::Plugin::SiteMap::OMIT_ROUTES;
            }
        }
    }

    return sort(@urls);
}

=head1 AUTHOR

James Ronan, C<< <james at ronanweb.co.uk> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-sitemap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-SiteMap>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::SiteMap


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-SiteMap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-SiteMap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-SiteMap>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-SiteMap/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 James Ronan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Dancer::Plugin::SiteMap
