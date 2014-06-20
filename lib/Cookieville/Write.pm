package Cookieville::Write;

=head1 NAME

Cookieville::Write - Controller for changing data in a result

=cut

use Mojo::Base 'Mojolicious::Controller';

=head1 METHODS

=head2 delete

Delete data from the database.

=cut

sub delete {
  my $self = shift;
  my $rs = eval { $self->db->resultset($self->stash('source')) };
  my $row;

  unless ($rs) {
    return $self->render(json => { message => 'No source by that name.' }, status => 404);
  }

  $row = $rs->find($self->stash('id'));
  $row->delete if $row;

  $self->render(json => { n => $row ? 1 : 0 });
}

=head2 patch

Used to patch a record in the database.

=cut

sub patch {
  my $self = shift;
  my $source = $self->stash('source');
  my $rs = eval { $self->db->resultset($source) };
  my $data = $self->req->json;
  my $row;

  unless ($data) {
    return $self->render(json => { message => 'Invalid JSON body.' }, status => 400);
  }
  unless ($rs) {
    return $self->render(json => { message => 'No source by that name.' }, status => 404);
  }

  $row = $rs->find($self->stash('id'));

  unless ($row) {
    return $self->render(json => { message => qq(No such record in "$source" source.) }, status => 404);
  }

  $row->set_column($_ => $data->{$_}) for keys %$data;
  $row->update;
  $self->render(json => { data => { $row->get_columns } });
}

=head2 update_or_insert

Used to update or insert a record in the database.

=cut

sub update_or_insert {
  my $self = shift;
  my $source = $self->stash('source');
  my $rs = eval { $self->db->resultset($source) };
  my $data = $self->req->json;
  my ($in_storage, $row);

  unless ($data) {
    return $self->render(json => { message => 'Invalid JSON body.' }, status => 400);
  }
  unless ($rs) {
    return $self->render(json => { message => 'No source by that name.' }, status => 404);
  }

  if ($self->_can_find($data, $rs->result_source)) {
    $row = $rs->find_or_new($data);
    $in_storage = $row->in_storage;
    $row->in_storage ? $row->update($data) : $row->insert;
  }
  else {
    $row = $rs->create($data);
    $row->discard_changes;
    $in_storage = 0;
  }

  $self->render(
    json => {
      inserted => $in_storage ? 0 : 1,
      data => { $row->get_columns },
    },
  );
}

sub _can_find {
  my ($self, $data, $source) = @_;
  my %unique_constraints = $source->unique_constraints;

  for my $c (values %unique_constraints) {
    return 1 if @$c == grep { exists $data->{$_} } @$c;
  }

  return 0;
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
