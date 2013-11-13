package Dancer::Template::Haml;

use strict;
use warnings;

use Dancer::App;
use Text::Haml;
use Dancer::FileUtils 'path';

use vars '$VERSION';
use base 'Dancer::Template::Abstract';

our $VERSION = '0.01';

my $_engine;

# skip check for views
sub view_exists {
  my $self = shift;
  my $view_path = shift;

  return 1; 
}

sub view {
 my $self = shift; 
 my $view = shift;

 return $view;
}

sub layout {
  my ($self, $layout, $tokens, $content) = @_;
  my %haml_args = %{$self->config};

  $_engine->escape_html(0);

  my $full_content;
  if (ref $haml_args{path} eq 'HASH') { # virtual path
    my $layout_path = "layouts/$layout.haml";

    # if found layout
    if (grep { m[$layout_path] } keys $haml_args{path}) {
      $full_content = Dancer::Template->engine->render(
        $layout_path, {%$tokens, content => $content});
    } else {
      $full_content = $content;
      Dancer::Logger::error("Defined layout ($layout) was not found!");
    }
  } else {
    my $layouts_dir = path(Dancer::App->current->setting('views'), 'layouts');
    my $layout_path;
    for my $layout_name ($self->_template_name($layout)) {
      $layout_path = path($layouts_dir, $layout_name);
      last if -e $layout_path;
    }

    if (-e $layout_path) {
      $full_content = Dancer::Template->engine->render(
        $layout_path, {%$tokens, content => $content});
    } else {
      $full_content = $content;
      Dancer::Logger::error("Defined layout ($layout) was not found!");
    }
  }

  $full_content;
}

sub init { 
  my $self = shift;

  my $app    = Dancer::App->current;
  my %haml_args = %{$self->config};

  # Set default path for header/footer etc.
  if (ref $haml_args{path} eq 'HASH') { # virtual path
    $haml_args{path} = [$haml_args{path}];
  } else {
    $haml_args{path} ||= [];
  }

  my $views_dir = $app->setting("views") || "";
  push @{ $haml_args{path} }, $views_dir
    if !grep { $_ eq $views_dir } @{ $haml_args{path} };

  $_engine = Text::Haml->new(%haml_args);
}

sub render($$$) {
  my ($self, $template, $tokens) = @_;

  my $content = q{};
  $content = $_engine->render_file($template, %$tokens)
    or die $_engine->error;

  # In the method layout set escape_html in 0 to insert the contents of a page
  # For all other cases set escape_html 1
  $_engine->escape_html(1);

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

=head1 COOKBOOK

=head2 Using templates in section __DATA__

You can also define a template in section __DATA__:

  use Data::Section::Simple qw/get_data_section/;

  my $vpath = get_data_section;

  set template => 'haml';

  get '/bazinga', sub {
    template 'bazinga' => {
      title => 'Bazinga!',
      content => 'Bazinga?',
    };
  };

  __DATA__

  @@ bazinga.haml
  !!! 5
  %html{ :xmlns => "http://www.w3.org/1999/xhtml", :lang => "en", "xml:lang" => "en"}
    %head
      %meta(charset= $settings->{charset})
      %title= $title
   %body
    #content
      %strong= $content

Using layouts in section __DATA__:

  use Data::Section::Simple qw/get_data_section/;

  my $vpath = get_data_section;

  set template  => 'haml';
  set layout    => 'main';

  get '/bazinga', sub {
    template 'bazinga' => {
      content2 => 'Bazinga?',
      grass   => 'Green!',
    };
  };

  __DATA__

  @@ layouts/main.haml
  !!! 5
  %html
    %head
      %meta(charset = $settings->{charset})
      %title Bazinga
    %body
      %div(style="color: green")= $content
      #footer
        Powered by
        %a(href="http://perldancer.org/") Dancer
        = $dancer_version

  @@ bazinga.haml
  %strong= $content2
  %p= $grass
  %em text

layout must be the path 'layouts/layout_name.haml', where
layout_name - the name specified in the variable layout:

  set layout => 'main';

In this example, enter main.


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
