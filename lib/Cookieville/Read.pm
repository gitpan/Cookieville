package Cookieville::Read;

=head1 NAME

Cookieville::Read - Controller for getting data from the schema

=cut

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON 'j';

=head1 METHODS

=head2 search

Get data from a given source.

=cut

sub search {
  my $self = shift;
  my $rs = eval { $self->db->resultset($self->stash('source')) };
  my $q = j $self->param('q');
  my %extra;

  unless ($rs) {
    return $self->respond_to(
      csv => sub { shift->render(text => 'No source by that name.', status => 404); },
      txt => sub { shift->render(text => 'No source by that name.', status => 404); },
      any => sub { shift->render(json => { message => 'No source by that name.' }, status => 404); },
    );
  }
  unless (ref $q eq 'HASH') {
    return $self->respond_to(
      csv => sub { shift->render(text => 'Invalid (q) query param.', status => 400); },
      any => sub { shift->render(json => { message => 'Invalid (q) query param.' }, status => 400); },
    );
  }

  $extra{order_by} = j $self->param('order_by') if $self->param('order_by');
  $extra{page} = $self->param('page') if $self->param('page');
  $extra{rows} = $self->param('limit') if $self->param('limit');

  $self->stash(rs => $rs->search_rs($q, \%extra))->respond_to(
    csv => \&_search_as_csv,
    txt => \&_search_as_csv,
    any => \&_search_as_json,
  );
}

sub _search_as_csv {
  my $self = shift;
  my $rs = $self->stash('rs');
  my @columns = $rs->result_source->columns;
  my @csv = (join ',', @columns);

  while(my $row = $rs->next) {
    push @csv, join ',', map {
      my $v = $row->get_column($_);
      $v =~ s!"!""!g;
      $v =~ /[\s,]/ ? qq("$v") : $v;
    } @columns;
  }

  $self->render(text => join '', map { "$_\n" } @csv);
}

sub _search_as_json {
  my $self = shift;
  my $rs = $self->stash('rs');
  my @data;

  while(my $row = $rs->next) {
    push @data, { $row->get_columns };
  }

  $self->render(json => { data => \@data });
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
