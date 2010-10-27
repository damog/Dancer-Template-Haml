package Dancer::Template::Haml;

use strict;
use warnings;

use Text::Haml;
use Dancer::FileUtils 'path';

use vars '$VERSION';
use base 'Dancer::Template::Abstract';

our $VERSION = '0.01';

my $_engine;

sub init {
    my ($self) = @_;
    my $haml_config = {
        format      => 'xhtml',
        escape_html => 1,
        namespace   => '',
        %{$self->config},
    };

    $_engine = Text::Haml->new(%{$haml_config});

    # Filters
    # Conventional defaults for filter definition
    my $filters_conventions = {
        textile       => { module => 'Text::Textile', renderer => 'textile' },
        markdown      => { module => 'Text::Markdown', renderer => 'markdown' },
        multimarkdown => { module => 'Text::MultiMarkdown', renderer => 'markdown' },
        cdata         => { renderer => 'sub {"<![CDATA[\n $_[0]\n]]>"}' },
        css           => { renderer => 'sub {"<style type=\'text/css\'>\n/*<![CDATA[*/\n $_[0]\n/*]]>*/\n</style>"}' },
    };

    # Filters requested in framework config: configure and activate
    my $cf_act = $self->config->{filters_activate};

    my $f_sub;

    # Derive the form of, and then assign, filter's sub{}
    # Why the extensive multimethod dispatch-like arg type testing and messaging,
    # contrary to the current vogue?
    #
    # Similar to users of complete frameworks, microframework users will often rely on
    # maintainers to configure the main services, but in contrast may later provide
    # their own snippets of code (such as routes) and may customize the configuration.
    #
    # The code below allows such customizations.
    #
    # Type checking, early binding (including two cases of explicit package binding),
    # plus resolution of string scalars, are used in hopes of providing modest
    # assistance for users venturing into this unfamiliar territory.
    #
    # Nonetheless some opaqueness remains: the code relies on closures; additionally,
    # late-binding of methods and of functions are also offered.
    #
    # A complete dynamic typing system would have led to a less cluttered (more
    # understandable and maintainable) implementation, but such are the (adroit)
    # tradeoffs in Dancer-pre-Perl6. Even then, because of opaque runtime errors
    # related to user selections of external libraries or of naming conflicts,
    # such beauty would come at the expense of making things even more
    # confusing for (and frustrating the adoption by) these users.
    #
    # Feel differently? There's a good possibility you are correct: fork and muck.

    # Model-type patterns for defining filters:
    # 1. Conventional object-oriented
    #       f_n:(f_obj(f_mod,parms), rndr([0]))
    # 2. Not OO, use the given module: assume named renderer uses conventional args
    #       f_n:(f_mod, rndr([0],parms))
    # 3. Not OO, using given module: assume renderer named with own arguments ref'ing $_[0]
    #       f_n:(f_mod, rndr)
    # 4. Functional, no module: expect renderer defined in scope, uses conventional args
    #       f_n:(rndr([0],parms))
    # 5. Functional: no module: rndrr will appear; use convntnl args or own iface ref'ing $_[0]
    #       f_n:(rndr)

FILTER:
    foreach my $f_n (keys %{$cf_act}) {
        my $cf_module   = delete $cf_act->{$f_n}->{module}   || $filters_conventions->{$f_n}->{module}   || undef;
        my $cf_renderer = delete $cf_act->{$f_n}->{renderer} || $filters_conventions->{$f_n}->{renderer} || $f_n;
        my $filter_params = $cf_act->{$f_n};

        my($f_mod, $f_modimpt) = split / /, $cf_module, 2 if $cf_module;
        $f_modimpt ||="";
        if ($f_mod) {
            warn("Failed require $f_mod for Haml filter [$f_n]; filter now unavailable."), next FILTER
                unless eval "require $f_mod";
            eval "$f_mod->import $f_modimpt" unless $f_modimpt =~ m|^\(\s*\)|;

            # Does filter follow object-oriented implementation conventions of the ancients?
            if ( $f_mod->can('new') ) {
                my $f_obj = $f_mod->new(%{$filter_params}) ;
                warn("Method [$cf_renderer] unavailable through module $f_mod for filter [$f_n];"
                     . " filter now unavailable."), next FILTER
                    unless $f_mod->can($cf_renderer);
               # DTHsub <model:1> f_n:(f_obj(f_mod,parms), rndr([0]))
               # $f_sub = sub { $f_obj->$cf_renderer($_[0]) };
               $f_sub = eval 'sub { $f_obj->'.$cf_renderer.'($_[0]) }';
            }
            # Not OO, but then perhaps the specific, given, module provides?
            else {
                    {
                      no strict 'refs';
                      if ( *{ "${f_mod}::$cf_renderer" }{CODE} ) {
                          # Early bind to specified module, set up as func call with specific interface
                          # DTH <fsub model:2> f_n:(f_mod, rndr([0],parms))
                          # $f_sub = sub { "${f_mod}::$cf_renderer"->($_[0], %{$filter_params}) };
                          $f_sub = eval 'sub { "'."${f_mod}::$cf_renderer".'"->($_[0], %{$filter_params}) }' ;
                      }
                      else {
                          # Presume func/class will appear later, user knows it supports needed iface
                          # Or, possibly, renderer spec'd with arglist
                          # DTHfsub <model:3> f_n:(f_mod, rndr)
                          $f_sub = eval "sub { ${f_mod}::$cf_renderer }";
                      }
                    }
            }
        }
          # No module identified, perhaps function in scope?
        else {
            if ( defined ( &{$cf_renderer} ) ) {
                # DTH <fsub model:4> f_n:(rndr([0],parms))
                # {no strict 'refs'; $f_sub = sub { &$cf_renderer($_[0], %{$filter_params})};  }
                $f_sub = eval 'sub { &' . $cf_renderer . '($_[0], %{$filter_params}) }';
            }
            # Presumably author knows func will exist at runtime, provides appropriate iface
            # Or, possibly, renderer spec'd with arglist
            else {
                warn("Function [$cf_renderer] not a code ref for filter [$f_n];"
                     . " filter now unavailable."), next FILTER
                    unless ref (eval $cf_renderer) eq 'CODE';
                # DTH <fsub model:5> f_n:(rndr)
                $f_sub = eval $cf_renderer;
            }
        }

        $_engine->add_filter( $f_n => $f_sub ) if $f_sub;
    }

    # Helpers
    # Conventional defaults for helper definition
    my $helpers_conventions = {
       #Template:  name    => { helper => 'sub { }' },
       tictoc => { helper => 'sub {time}'},
    };

    # Helpers provided/defined in framework config: configure and activate
    my $ch_act = $self->config->{helpers_activate};

    my $h_sub;

    # Assign helper's sub{}
    # We don't bother checking that the supplied string produces a coderef.
    # We simply prepare the closure with the config data,
    # and register/add the user's provided helper.
HELPER:
    foreach my $h_n (keys %{$ch_act}) {
        my $ch_helper = $ch_act->{$h_n}->{helper} || $helpers_conventions->{$h_n}->{helper} || $h_n;
        my $helper_params = $ch_act->{$h_n};

        warn("Expression [$ch_helper] not a code ref for helper [$h_n];"
             . " helper now unavailable."), next HELPER
            unless ref (eval $ch_helper) eq 'CODE';
        my $h_sub = eval $ch_helper;
        $_engine->add_helper( $h_n => $h_sub ) if $h_sub;
    }

} #end:init

sub view {
    my ($self, $view) = @_;
    $view .= ".haml" if $view !~ /\.haml$/;
    return path(Dancer::Config::setting('views'), $view);
}

sub layout {
    my ($self, $layout, $tokens, $content) = @_;

    $layout .= '.haml' if $layout !~ /\.haml$/;
    $layout = path(Dancer::Config::setting('views'), 'layouts', $layout);

    my $full_content =
      Dancer::Template->engine->render($layout,
        {%$tokens, content => $content});
    $full_content;
}

sub render {
    my ($self, $template, $tokens) = @_;

    die "'$template' is not a regular file"
      unless ref($template) || (-f $template);

    my $content = q{};
    $content = ref($template)
               ? $_engine->render($$template,%$tokens)
               : $_engine->render_file($template, %$tokens)
        or die $_engine->error;
    return $content;
}

1;
__END__

=pod

=head1 NAME

Dancer::Template::Haml - Haml wrapper for Dancer

=head1 SYNOPSIS

 set template => 'haml';
 
 get '/bazinga', sub {
 	template 'bazinga' => {
 		title => 'Bazinga!',
 		content => 'Bazinga?',
 	};
 };

Then, on C<views/bazinga.haml>:

 !!!
 %html{ :xmlns => "http://www.w3.org/1999/xhtml", :lang => "en", "xml:lang" => "en"}
   %head
     %title= $title
   %body
     #content
       %strong= $content

And... bazinga!

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Text::Haml> module.

In order to use this engine, set the following setting as the following:

    template: haml

This can be done in your config.yml file or directly in your app code with the
B<set> keyword.

This module overrides L<Dancer::Template::Abstract> methods B<view> and B<layout>
to automatically append an absent ".haml" suffix. 

=head1 FILTERS

=head2 Built-In Filters

L<Text::Haml> implements a subset of the filters named in the Haml
reference L<http://haml-lang.com/docs/yardoc/file.HAML_REFERENCE.html>.
These filters may be used in Haml markup without any additional
activation or configuration. As of this writing (v0.990103):

          plain
          escaped
          preserve
          javascript

=head2 Custom Filters

The Haml reference provides for custom filters; L<Text::Haml>
implements a suitable interface C<$haml-E<gt>add_filter( name, sub )>.

The L<Dancer::Template::Haml> engine now uses this interface to
support the activation of additional Haml filters. A handful of
custom filters are preconfigured according to their respective
conventional use. The configuration may be changed, and additional
custom filters defined.

The following activates preconfigured custom filters, making
Markdown and Textile available in Haml markup.

    haml:
      filters_activate:
          markdown:
          textile:

If other than the conventional utilization and default configuration
options are desired, provide a mapping:

    haml:
      filters_activate:
          markdown:
              tab_width: 2
              trust_list_start_value: 1
              empty_element_suffix: />
          textile:
              char_encoding: utf-8
              trim_spaces: 1
              full_page: 0


=head2 Custom Filters Conventions

Filters activated through L<Dancer::Template::Haml> follow,
for the most part, one of two conventions:

=over

=item A.

An B<object-oriented interface>, using a new() constructor taking
as optional arguments configuration settings in name, value
pairs, plus providing an eponymous invocation method taking
a single string scalar, returning a string; or

=item B.

A B<procedural interface>, using an eponymous invocation function
taking a string scalar, followed by optional configuration
settings in name, value pairs, returning a string.

=back

Variations of this are also supported. See below.


=head2 Filters Available Through Activation

Without additional configuration (you still must install the
required modules), the following named filters may be activated
through C<filters_activate> and use the conventional facilities
of the respective implementations (shown here are the equivalent
configuration directives):

    haml:
      filters_activate:
          markdown:
              module:    Text::Markdown
              renderer:  markdown
          textile:
              module:    Text::Textile
              renderer:  textile
          multimarkdown:
              module:    Text::MultiMarkdown
              renderer:  markdown
          cdata:
              renderer:  sub {"<![CDATA[\n $_[0]\n]]>"}
          css:
              renderer:  sub {"<style type='text/css'>\n
                         /*<![CDATA[*/\n $_[0]\n/*]]>*/\n</style>"}


=head2 Making Additional Filters Available

Through configuration, you may describe and activate additional
filters, as follows:

    haml:
      filters_activate:
          FILTERNAME:
              module:    MODULE LIST
              renderer:  RENDERER
              param:     value ...

=over

=item FILTERNAME

Filter is invoked by the token FILTERNAME. This token
must be a valid Perl (and Ruby) identifier. This mapping
is passed through to the filter, or may be referenced in
the RENDERER sub, as B<$filter_params>.

=item MODULE LIST

The 'module:' mapping describes the Perl module to use. The
initial token is passed to 'require' as the module name;
any following string is then passed to import
(unless it is '()', which suppresses that call).

=item RENDERER

The 'renderer:' mapping describes the method or function to
use, or alternatively, the code fragment to be evaluated.
The RENDERER string must complete one of five models,
otherwise a warning is issued during configuration time.

If the module is known (named or defaults), and the renderer
string is a proper identifier, then: if module->can("new"),
the renderer is invoked as a method of that Class (Model 1.);
otherwise renderer is invoked as a function (Model 2.).

If the module is known, but the renderer string provided
is B<not> a proper identifier, the string is presumed
to be a sub to be invoked through 'eval' and referencing
$_[0] in the provided calling interface (Model 3.).

If the module is B<unknown>, the renderer string must be the
name of a function available in the current context (Model 4.),
or is presumed to be a sub to be invoked through 'eval' and
referencing $_[0] in the provided calling interface (Model 5.).

In all cases, if the renderer string is not known, it is
inferred from the filter name.

=back

=head1 HELPERS

=head2 Custom Helpers

The Haml reference provides for custom helpers; L<Text::Haml>
implements a suitable interface C<$haml-E<gt>add_helper( name, sub )>.

The L<Dancer::Template::Haml> engine now uses this interface to
support the activation of custom Haml helpers. One (token) helper
is provided as default: tictoc, invoking time().

Helpers may be described and activated, as follows:

    haml:
      helpers_activate:
          HELPERNAME:
              helper:  HELPERSUB
              param:  value ...

=over

=item HELPERNAME

Helper is invoked by the token HELPERNAME. This token
must be a valid Perl (and Ruby) identifier. This mapping
(that is, the parameters configured) may be referenced
in HELPERSUB, as B<$helper_params>.

When vars_as_subs is true, the namespace for helper names
and var names overlaps; helper names take precedence.

=item HELPERSUB

The 'helper:' mapping describes the code fragment to be
added as the helper. It must evaluate to a coderef, but
is otherwise unverified.

The helper is passed parameters. The first is known as
B<helpers_arg>. This is a top-level Haml parameter. In
the case of activating filters through configuration,
the likely best value is the default, which is the
instance of L<Text::Haml>.

The argument list, as invoked in the .haml file, is
passed as the remaining parameter(s).

A string must be returned.

The closure includes B<%helper_params>, which is the
mapping for the parameters provided in B<helpers_activate>.

=back

Sample mapping riffed off of L<Text::Haml>:

In the configuration file:

    haml:
      helpers_activate:
          foo:
              helper: sub { shift; my $s = shift;
                      $s =~ s/r/z/; $s; }

In the Haml file:

   %p
    = foo("bar")

   %p= foo("bar")

Result:

  <p>
   baz
  </p>

  <p>baz</p>

=head1 SEE ALSO

L<Dancer>, L<Text::Haml>

=head1 TODO

The usage of helpers, filters and attributes. This will be expanded as
Dancer expands its capabilities to take specific parameters for each templating engine
it supports.

=head1 AUTHOR

This module has been written by David Moreno, L<http://stereonaut.net/>. This module
was heavily based on Franck Cuny's L<Dancer::Template::MicroTemplate>.

Support for filters and helpers, their defaults, and activation through the
Dancer configuration file was written by Nick Ragouzis, enosis@github.com.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut
