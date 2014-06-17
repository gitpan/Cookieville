package Cookieville::Schema;

=head1 NAME

Cookieville::Schema - Controller for running actions on the schema

=cut

use Mojo::Base 'Mojolicious::Controller';

=head1 METHODS

=head2 index

Render information about this application.

=cut

sub index {
  my $self = shift;

  $self->render(
    json => {
      map { $_ => $self->${ \ "_info_$_" } } split /,/, +($ENV{COOKIEVILLE_INFO} // 'version,source,resources')
    },
  );
}

=head2 sources_list

Render a list of sources.

=cut

sub sources_list {
  my $self = shift;
  my @sources = sort $self->db->sources;

  $self->respond_to(
    csv => sub { shift->render(text => join ",", @sources); },
    txt => sub { shift->render(text => join "", map { "$_\n" } @sources); },
    any => sub { shift->render(json => \@sources); },
  );
}

=head2 source_schema

Render the source definition.

=cut

sub source_schema {
  my $self = shift;
  my $source = eval { $self->db->source($self->stash('source')) };

  if ($source) {
    $self->render(
      json => {
        columns => $self->_columns_from($source),
        name => $source->name,
        primary_columns => [ $source->primary_columns ],
      },
    );
  }
  else {
    $self->render(json => { message => 'No source by that name.' }, status => 404);
  }
}

sub _columns_from {
  my ($self, $source) = @_;
  my %columns;

  for my $name ($source->columns) {
    $columns{$name} = $source->column_info($name);
  }

  return \%columns;
}

sub _info_resources {
  +{
    schema_source_list => [ "GET", "/sources" ],
    schema_for_source => [ "GET", "/:source/schema" ],
    source_select => [ "GET", "/:source/select?q=:json&limit=:int&order_by:json" ],
    source_delete => [ "DELETE", "/:source/:id" ],
    source_patch => [ "PATCH", "/:source/:id" ],
    source_update_or_insert => [ "PUT", "/:source" ],
  };
}

sub _info_source {
  'https://github.com/jhthorsen/cookieville';
}

sub _info_version {
  eval { Cookieville->VERSION } || 0;
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
