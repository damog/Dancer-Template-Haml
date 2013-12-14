use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
  #use lib '../../lib';
  use_ok( 'Dancer::Template::Haml' ) or die 'Template engine unavailable';
}

diag( "Testing Dancer::Template::Haml $Dancer::Template::Haml::VERSION, Perl $], $^X" );

use Dancer::Template;
my $e;

my $config;


# filters_activate rendering tests
# Notes:
# - Here we just verify successful rendering; see ./01_engine_init/*.t for initialization
# - We verify simple versions using Perl core, to avoid problems with module availability
# - The 'Model-type' for activation, mentioned below, are documented in Dancer::Template::Haml

my $hamltemplate;
my $htmloutput;
my $htmlexpected;



# filters_activate: Model-type 5 -- renderer as provided sub {}
$config = {
    engines => {
         haml => {
             filters_activate => {
                   ucexpr => {
                          renderer => 'sub { uc $_[0] }'
                   },
             },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%p
  :ucexpr
    this text upcased
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<p>
THIS TEXT UPCASED
</p>
HTML
is($htmloutput, $htmlexpected, "Filter: Upper Case Expression (Model-type 5)" );



# filters_activate: Model-type 3 -- renderer as module::renderer
$config = {
    engines => {
         haml => {
            filters_activate => {
                   textwrap => {
                          module => 'Text::Wrap',
                          renderer => 'wrap("\t","",$_[0])',
                   },
            },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%p
  :textwrap
    I don't believe people are looking for the meaning of life as much as they are looking for the experience of being alive --Joseph Campbell
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<p>
	I don't believe people are looking for the meaning of life as much
as they are looking for the experience of being alive --Joseph Campbell
</p>
HTML
is($htmloutput, $htmlexpected, "Filter: Textwrap (Model-type 3)" );



# filters_activate: Model-type 1 -- module and renderer, OO-style (hybrid)
$config = {
    engines => {
         haml => {
            escape_html => 0,
            preserve => [ 'pre', 'textarea', 'code' ],
            pretty => 1,
            format => 'xhtml',
            filters_activate => {
                   sha1b64 => {
                          module => 'Digest::SHA (sha1_base64)',
                          renderer => 'sha1_base64',
                   },
            },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%p
  :sha1b64
    Get a life!
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
like ($htmloutput, qr/\S{27}/, "Filter: SHA1 Base64 digest (Model-type 1 & 2 hybrid)" );



# filters_activate: Model-type 5 -- predefined convention
$config = {
    engines => {
         haml => {
            escape_html => 0,
            preserve => [ 'pre', 'textarea', 'code' ],
            pretty => 1,
            format => 'xhtml',
            filters_activate => {
                   cdata => { },
            },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%p
  :cdata
    function sleepless() {alert("WAKE UP!")}
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<p>
<![CDATA[
 function sleepless() {alert("WAKE UP!")}
]]>
</p>
HTML
is($htmloutput, $htmlexpected, "Filter: CDATA wrapper (Model-type 5)" );

