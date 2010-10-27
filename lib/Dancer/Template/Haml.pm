package Dancer::Template::Haml;

use strict;
use warnings;

use Text::Haml;
use Dancer::FileUtils 'path';

use vars '$VERSION';
use base 'Dancer::Template::Abstract';

our $VERSION = '0.01';

my $_engine;

sub init { $_engine = Text::Haml->new }

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
     %title= title
   %body
     #content
       %strong= content

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


=head1 SEE ALSO

L<Dancer>, L<Text::Haml>

=head1 TODO

The usage of helpers, filters and attributes. This will be implemented once
Dancer has capabilities to take specific parameters for each templating engine
it supports.

=head1 AUTHOR

This module has been written by David Moreno, L<http://stereonaut.net/>. This module
was heavily based on Franck Cuny's L<Dancer::Template::MicroTemplate>.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut
