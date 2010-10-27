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


# helpers_activation initialization tests
# Notes:
# - Just verify successful init of engine; see ./02_template_render/*.t for results
# - Only simple helpers are activated here, to avoid problems



# helpers_activate: tictoc
$config = {
    engines => {
         haml => {
            helpers_activate => {
                   tictoc => {},
            },},},};
eval { $e = Dancer::Template->init('haml',$config) };
is $@, '', 'Engine init: with helpers_activate predefined - convention (tictoc)';



# helpers_activate: time
$config = {
    engines => {
         haml => {
            helpers_activate => {
                   curt => {
                          helper => 'sub {time}'
                   },
            },},},};
eval { $e = Dancer::Template->init('haml',$config) };
is $@, '', 'Engine init: with helpers_activate  (curt).';



# helpers_activate: baddef
$config = {
    engines => {
         haml => {
            helpers_activate => {
                   baddef => {},
            },},},};
eval { $e = Dancer::Template->init('haml',$config) };
is $@, '', 'Engine init: with helper_activate (baddef).';
diag ( 'helper [baddef] should have provoked a warning, but not an exception' );
# Expression [baddef] not a code ref for helper.*now unavailable

