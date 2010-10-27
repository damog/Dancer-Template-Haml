use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
  use lib '../../lib';
  use_ok( 'Dancer::Template::Haml' ) or die 'Template engine unavailable';
}

diag( "Testing Dancer::Template::Haml $Dancer::Template::Haml::VERSION, Perl $], $^X" );

use Dancer::Template;
my $e;

my $config;


# helpers_activation rendering tests
# Notes:
# - Only simple helpers are activated here, to avoid problems
# - One (token) helper is predefined:
#    * tictoc (performs time())

my $hamltemplate;
my $htmloutput;
my $htmlexpected;



# helpers_activate: tictoc
$config = {
    engines => {
         haml => {
            helpers_activate => {
                   tictoc => {},
            },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%dir
  %p= tictoc
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
like ($htmloutput, qr/<dir>\n  <p>\d+<\/p>\n<\/dir>/, "Helper: tictoc" );



# helpers_activate: curt
$config = {
    engines => {
         haml => {
            helpers_activate => {
                   curt => {
                          helper => 'sub {time}'
                   },
            },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%dir
  %p= curt
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
like ($htmloutput, qr/<dir>\n  <p>\d+<\/p>\n<\/dir>/, "Helper: curt (time)" );



# helpers_activate: foo (from the Text::Haml doc)
$config = {
    engines => {
         haml => {
            helpers_activate => {
                   foo => {
                          helper => 'sub { shift; my $s = shift;
                                     $s =~ s/r/z/; $s;}'
                   },
            },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%dir
  %p= foo("bar")
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = <<'HTML';
<dir>
  <p>baz</p>
</dir>
HTML
is ($htmloutput, $htmlexpected, "Helper: foo" );

