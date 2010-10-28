use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
  #use lib '../../lib';
  use_ok( 'Dancer::Template::Haml' ) or die 'Template engine unavailable';
}

diag( "Testing Dancer::Template::Haml $Dancer::Template::Haml::VERSION, Perl $], $^X" );

use Dancer::Template;
my $e;

my $config;


# Empty config
$e = Dancer::Template->init('haml');
is_deeply ($e->config, {}, 'Default Engine config == empty hash ref');


# Basic config
$config = {
    engines => {
         haml => {
            pretty => 0,
            format => 'xhtml'
         },
    },};
$e = Dancer::Template->init('haml',$config);
is ($e->type, 'template', 'Reads: Engine type == template');
is ($e->name, 'haml', 'Reads: Template engine name == haml');

is ($e->config->{escape_html}, undef, 'escape_html == undef');
# Note: Dancer::Template::Haml uses lexical haml_config to acquire
# and set configuration variables; those defaults/settings, such
# as the default escape_html = 1, do not reach the outer scope

is ($e->config->{pretty}, '0', 'Reads: Haml config:pretty == 0');
is ($e->config->{format}, 'xhtml', 'Reads: Haml config:format == xhtml');

