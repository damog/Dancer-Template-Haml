use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
  #use lib '../../lib';
  use_ok( 'Dancer::Template::Haml' ) or die 'Template engine unavailable';
}

diag( "Testing Dancer::Template::Haml $Dancer::Template::Haml::VERSION, Perl $], $^X" );

use Dancer::Template;
my $e;

my $config;


# filters_activation initialization tests
# Notes:
# - Here we just verify successful init of engine; see ./02_template_render/*.t for results
# - We verify simple versions using Perl core, to avoid problems with module availability
# - The 'Model-type' for activation, mentioned below, are documented in Dancer::Template::Haml



# filters_activate: Model-type 5 -- renderer as provided sub {}
$config = {
    engines => {
         haml => {
             filters_activate => {
                   ucexpr => {
                          renderer => 'sub { uc $_[0] }'
                   },
             },},},};
eval { $e = Dancer::Template->init('haml',$config) };
is $@, '', 'Engine init: with filter_activate Model-type 5 (ucexpr).';



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
eval { $e = Dancer::Template->init('haml',$config) };
is $@, '', 'Engine init: with filter_activate Model-type 3 (textwrap).';



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
eval { $e = Dancer::Template->init('haml',$config) };
is $@, '', 'Engine init: with filter_activate Model-type 1 (hybrid) (sha1b64).';
# Note: 'hybrid' because although this module 'can' sha1_base64
#       and so it is defined as object-oriented, and called in that form
#       the ultimate module handling will be functional
#       So, really more a Model-type 2.



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
eval { $e = Dancer::Template->init('haml',$config) };
is $@, '', 'Engine init: with filter_activate Model-type 5 - predefined, convention (cdata).';



# filters_activate: Model-type 5 -- baddef
$config = {
    engines => {
         haml => {
            escape_html => 0,
            preserve => [ 'pre', 'textarea', 'code' ],
            pretty => 1,
            format => 'xhtml',
            filters_activate => {
                   baddef => {}
            },},},};
eval { $e = Dancer::Template->init('haml',$config) };
is $@, '', 'Engine init: with filter_activate Model-type 5 (baddef).';
diag ( 'Notice: filter [baddef] should have provoked a warning, but not an exception' );
# Function [baddef] not a code ref for filter.*now unavailable
