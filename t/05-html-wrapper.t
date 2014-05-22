use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 4;

# Set up the details of a wrapper template to use.
my $wrapper_filename = 'test-sitemap-wrapper.template';
my $wrapper_content = <<WRAPPER;
<div id="wrapper-test">
<% sitemap %>
</div>
WRAPPER

my $wrapper_location = '.';
open my $wrapper_fh, '>', $wrapper_location . "/" . $wrapper_filename;
if ($wrapper_fh) {
    print {$wrapper_fh} $wrapper_content;
    close $wrapper_fh;
}

{
    use Dancer;

    setting(views => $wrapper_location);
    setting(plugins => {
        SiteMap => {
            html_wrapper => $wrapper_filename,
        },
    });

    eval 'use Dancer::Plugin::SiteMap';
    die $@ if $@;

    get '/foo'         => sub {};
    get '/bar'         => sub {};
}

use Dancer::Test;

SKIP: {
    skip "Couldn't create template file to test with", 2
        unless -f $wrapper_location . "/" . $wrapper_filename;

    # we run these tests twice to make sure we can call our routes
    # several times and get the same result
    foreach (1 .. 2) {
        my $res = dancer_response( GET => '/sitemap' );
        my $expected_html = <<'EOHTML';
<div id="wrapper-test">
<h2>Site Map</h2>
<ul class="sitemap">
  <li><a href="/bar">/bar</a></li>
  <li><a href="/foo">/foo</a></li>
  <li><a href="/sitemap">/sitemap</a></li>
  <li><a href="/sitemap.xml">/sitemap.xml</a></li>
</ul>

</div>
EOHTML

        is $res->status, 200, "got /sitemap (turn: $_)";
        is $res->content, $expected_html, "got the proper sitemap content (turn: $_)";
    }
}

# Bin off the temporary wrapper template.
unlink $wrapper_location . "/" . $wrapper_filename
    if -f $wrapper_location . "/" . $wrapper_filename;

