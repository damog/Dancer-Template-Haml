use strict;
use warnings;
use Test::More tests =>10;

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
# - First run ../01_engine_init/*.t
# - Then run ./01_filters_basic.t, which tests filters without requiring modules, etc
# - This file contains tests for the filters predefined in Dancer::Template::Haml;
#   these are filters of common interest which also follow simple conventions.
#   To activate these filters, no module or renderer need be defined in the config:
#   the config need only include the filter name in filters_activate.
#   Except, of course, any required Perl module must be installed.
#    *  textile
#    *  markdown
#    *  multimarkdown
#    *  cdata
#    *  css

my $hamltemplate;
my $htmloutput;
my $htmlexpected;



# filters_activate: textile
SKIP: {
eval { require Text::Textile };
skip "Text::Textile not installed; skipping", 1 if $@;
$config = {
    engines => {
         haml => {
             filters_activate => {
                   textile => {},
             },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%dir
  :textile
    h2. head2
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<dir>
<h2>head2</h2>
</dir>
HTML
is($htmloutput, $htmlexpected, "Filter: Text::Textile" );
}



# filters_activate: markdown
SKIP: {
eval { require Text::Markdown };
skip "Text::Markdown not installed; skipping", 1 if $@;
$config = {
    engines => {
         haml => {
            filters_activate => {
                   markdown => {
                          trust_list_start_value => 1,
                   },
            },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%dir
  :markdown
    ## head2
    3.  Wrong Number
    1.  Wrong Order
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<dir>
<h2>head2</h2>

<ol start='3'>
<li>Wrong Number</li>
<li>Wrong Order</li>
</ol>

</dir>
HTML
is($htmloutput, $htmlexpected, "Filter: Text::Markdown" );
}



# filters_activate: multimarkdown
SKIP: {
eval { require Text::MultiMarkdown };
skip "Text::MultiMarkdown not installed; skipping", 1 if $@;
$config = {
    engines => {
         haml => {
            filters_activate => {
                   multimarkdown => {
                          heading_ids => 1,
                   },
            },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%dir
  :multimarkdown
    ## Head2
    *   Item
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<dir>
<h2 id="head2">Head2</h2>

<ul>
<li>Item</li>
</ul>

</dir>
HTML
is($htmloutput, $htmlexpected, "Filter: Text::Markdown" );
}



# filters_activate: cdata
$config = {
    engines => {
         haml => {
            filters_activate => {
                   cdata => {},
            },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%div
  :cdata
    def funct(); 1; end;
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<div>
<![CDATA[
 def funct(); 1; end;
]]>
</div>
HTML
is($htmloutput, $htmlexpected, "cdata" );



# filters_activate: css
$config = {
    engines => {
         haml => {
            filters_activate => {
                   css => {},
            },},},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%div
  :css
    table.hl {
      margin: 2em 0;
    }
    table.hl td.ln {
      text-align:right;
    }
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<div>
<style type='text/css'>
/*<![CDATA[*/
 table.hl {
margin: 2em 0;
}
table.hl td.ln {
text-align:right;
}
/*]]>*/
</style>
</div>
HTML
is($htmloutput, $htmlexpected, "css" );



# filters_activate: plain (Text::Haml builtin)
# (Empty 'filters_activate' or omit)
$config = {
    engines => {
         haml => {
            filters_activate => {
            },
         },},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%div
  :plain
    Plain
       Text
     Filter
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<div>
Plain
Text
Filter
</div>
HTML
is($htmloutput, $htmlexpected, "plain (Text::Haml builtin)" );



# filters_activate: escaped (Text::Haml builtin)
$config = {
    engines => {
         haml => {
         },},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%div
  :escaped
    <atag>This & That &amp; There</atag>
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<div>
&lt;atag&gt;This &amp; That &amp;amp; There&lt;/atag&gt;
</div>
HTML
is($htmloutput, $htmlexpected, "escaped (Text::Haml builtin)" );
#Will change under WSE Haml: calls for &amp; to NOT become &amp;amp;



# filters_activate: preserve (Text::Haml builtin)
$config = {
    engines => {
         haml => {
         },},};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%div
  :preserve
    Plain
       Text
     Filter
HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<div>
Plain&#x000A;Text&#x000A;Filter
</div>
HTML
is($htmloutput, $htmlexpected, "preserve (Text::Haml builtin)" );
#Will change under WSE Haml: calls for the leading whitespaces to be preserved



# filters_activate: javascript (Text::Haml builtin)
$config = {
    engines => {
         haml => {
         },
    },};
$e = Dancer::Template->init('haml',$config);
$hamltemplate = <<'HAML';
%div
  :javascript
    function fact(x) { if ( x<=1 ) return 1; return x * fact(x-1); }

HAML
{  no strict 'refs';
$htmloutput = $e->render( \$hamltemplate, $config );
}
$htmlexpected = << 'HTML';
<div>
<script type='text/javascript'>
  //<![CDATA[
    function fact(x) { if ( x<=1 ) return 1; return x * fact(x-1); }
  //]]>
</script>
</div>
HTML
is($htmloutput, $htmlexpected, "javascript (Text::Haml builtin)" );

