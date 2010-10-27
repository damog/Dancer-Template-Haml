use strict;
use warnings;
use Test::More tests =>5;

BEGIN {
  use lib '../../lib';
  use_ok( 'Dancer::Template::Haml' ) or die 'Template engine unavailable';
}

diag( "Testing Dancer::Template::Haml $Dancer::Template::Haml::VERSION, Perl $], $^X" );

use Dancer::Template;
my $e;

my $config;


# filters_activate rendering tests
# Notes:
# - First run ../01_engine_init/*.t
# - Then run ./01_filters_basic.t, which tests filters without requiring modules, etc
# - Then run ./02_template_render/02_filters_predef.t
# - This file contains tests for filters an author might define in the config
#   These are the filters defined, and the module dependencies:
#     - knuthreflow: Text::Reflow
#     - lorem_paras: Text::Lorem
#     - smartypants: Text::SmartyPants
#     - htmlbody:    LWP::Simple, HTML::TokeParser (Note: web query subject to failure)

my $hamltemplate;
my $htmloutput;
my $htmlexpected;



# filters_activate: Text::Reflow
SKIP: {
eval { require Text::Reflow };
skip "Text::Reflow not installed; skipping", 1 if $@;
$config = {
    engines => {
         haml => {
             filters_activate => {
                   knuthreflow => {
                          indent1 => '        ',
                          indent2 => '    ',
                          maximum => 65,
                          module => 'Text::Reflow',
                          renderer => 'reflow_string',
                   },
              },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%pre
 :knuthreflow
  To the People of the State of New York:

  AFTER an unequivocal experience of the inefficacy of the subsisting
  federal government, you are called upon to deliberate on a new
  Constitution for the United States of America. The subject speaks its
  own importance; comprehending in its consequences nothing less than the
  existence of the UNION...

  This idea will add the inducements of philanthropy to those of
  patriotism, to heighten the solicitude which all considerate and good
  men must feel for the event. Happy will it be if our choice should be
  directed by a judicious estimate of our true interests...

  Among the most formidable of the obstacles which the new Constitution
  will have to encounter may readily be distinguished the obvious interest
  of a certain class of men in every State to resist all changes which
  may hazard a diminution of the power, emolument, and consequence...
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<pre>
        To the People of the State of New York:

        AFTER an unequivocal experience of the inefficacy
    of the subsisting federal government, you are called upon
    to deliberate on a new Constitution for the United States
    of America.  The subject speaks its own importance;
    comprehending in its consequences nothing less than the
    existence of the UNION...

        This idea will add the inducements of philanthropy
    to those of patriotism, to heighten the solicitude which
    all considerate and good men must feel for the event.
    Happy will it be if our choice should be directed by a
    judicious estimate of our true interests...

        Among the most formidable of the obstacles which
    the new Constitution will have to encounter may readily
    be distinguished the obvious interest of a certain class
    of men in every State to resist all changes which may hazard
    a diminution of the power, emolument, and consequence...

</pre>
HTML
is($htmloutput, $htmlexpected, "Filter: Text::Reflow" );
}



# filters_activate: Text::Lorem
SKIP: {
eval { require Text::Lorem };
skip "Text::Lorem not installed; skipping", 1 if $@;
$config = {
    engines => {
         haml => {
             filters_activate => {
                   lorem_paras => {
                          module => 'Text::Lorem',
                          renderer => 'paragraphs',
                   },
             },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%p
  :lorem_paras
    3
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
like ($htmloutput, qr/<p>(\n[a-zA-Z .]+.\n){3}<\/p>/, "Filter: Text::Lorem" );
}



# filters_activate: Text::SmartyPants
SKIP: {
eval { require Text::SmartyPants };
skip "Text::SmartyPants not installed; skipping", 1 if $@;
$config = {
    engines => {
         haml => {
             filters_activate => {
                   smartypants => {
                          smarty_pants => '2',
                          module => 'Text::SmartyPants',
                          renderer => 'process( $_[0], $$filter_params{smarty_pants})'
                   },
              },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%p
  :smartypants
    This week---Monday--Friday---is Joe's        .
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<p>
This week&#8212;Monday&#8211;Friday&#8212;is Joe&#8217;s        .
</p>
HTML
is($htmloutput, $htmlexpected, "Filter: Text::SmartyPants" );
}



# filters_activate: 'htmlbody' using LWP::Simple and HTML::TokeParser
SKIP: {
eval { require LWP::Simple; require HTML::TokeParser };
skip "LWP::Simple and HTML::TokeParser must both be installed; skipping", 1 if $@;
$config = {
    engines => {
         haml => {
             filters_activate => {
                   htmlbody => {
                          renderer => 'sub {use LWP::Simple;require HTML::TokeParser;
                                       my $s=get($_[0]);
                                       my $p=HTML::TokeParser->new(\$s);$p->get_tag("body");
                                       $p->get_text("/body");}'
                   },
              },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%pre
  :htmlbody
    http://www.ndbc.noaa.gov/mobile/station.php?station=46026
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
like ($htmloutput, qr/(?s:<pre>\n\n NOAA Logo.*<\/pre>)/, "Filter: LWP::Simple + HTML::TokeParser" );
}

