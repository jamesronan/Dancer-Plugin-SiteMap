use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 4;

# Set up the details of a temporary template to use.
my $template_filename = 'test-sitemap-template.template';
my $template_content = <<WRAPPER;
<div id="template-test">
<% sitemap %>
</div>
WRAPPER

my $template_location = '.';
open my $template_fh, '>', $template_location . "/" . $template_filename;
if ($template_fh) {
    print {$template_fh} $template_content;
    close $template_fh;
}

{
    use Dancer;

    setting(views => $template_location);
    setting(plugins => {
        SiteMap => {
            html_template => $template_filename,
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
        unless -f $template_location . "/" . $template_filename;

    # we run these tests twice to make sure we can call our routes
    # several times and get the same result
    foreach (1 .. 2) {
        my $res = dancer_response( GET => '/sitemap' );
        my $expected_html = <<'EOHTML';
<div id="template-test">
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

# Bin off the temporary template.
unlink $template_location . "/" . $template_filename
    if -f $template_location . "/" . $template_filename;

