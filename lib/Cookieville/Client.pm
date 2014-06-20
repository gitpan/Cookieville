package Cookieville::Client;

=head1 NAME

Cookieville::Client - Client that talks with Cookieville server

=head1 DESCRIPTION

L<Cookieville::Client> is a client that talks with the L<Cookieville> server.

=head1 SYNOPSIS

  use Cookieville::Client;
  my $ua = Cookieville::Client->new(url => 'http://127.0.0.1/');
  my $res;

  $res = $ua->search(
            'SomeSource',
            { col_a => { like => '%42' } },
            { limit => 10 },
          );

  $res = $ua->delete(SomeSource => 123);
  $res = $ua->put(SomeSource => { col_a => 123 });
  $res = $ua->patch(SomeSource => 42 => { col_a => 123 });

=head2 Error handling

Blocking requests will throw an exception on error, while all callbacks
receive the error as a string. Example:

  use Mojolicious::Lite;

  get '/artists' => sub {
    my $c = shift->render_later;

    Mojo::IOLoop->delay(
      sub {
        my ($delay) = @_;
        $c->cookieville_helper->search(Artist => {}, $delay->begin);
      },
      sub {
        my ($delay, $err, $res) = @_;
        return $c->render_exception($err) if $err;
        return $c->render(json => $res->{data});
      },
    );
  };

=cut

use Mojo::Base -base;
use Mojo::JSON 'j';
use Mojo::UserAgent;
use Mojo::URL;

=head1 ATTRIBUTES

=head2 url

  $url_obj = $self->url;
  $self = $self->url($url_obj);

Holds the base URL to the L<Cookieville> server.
Default to "http://127.0.0.1/".

=cut

has url => sub { Mojo::URL->new('http://127.0.0.1/'); };
has _ua => sub { Mojo::UserAgent->new; };

=head1 METHODS

=head2 new

Will make sure "url" in constructor is indeed a L<Mojo::URL> object.

=cut

sub new {
  my $self = shift->SUPER::new(@_);

  $self->url(Mojo::URL->new($self->url)) if $self->url;
  $self;
}

=head2 delete

  $res = $self->delete($source => $id);
  $self = $self->delete($source => $id, $cb);

Used to DELETE a single record from C<$source>, identified by C<id>.

=cut

sub delete {
  my ($self, $source, $id, $cb) = @_;

  return $self->_blocking(delete => $source, $id) unless ref $cb eq 'CODE';
  return $self->_abort('Invalid source or id.', $cb) unless $source and defined $id;

  Scalar::Util::weaken($self);
  $self->_ua->delete(
    $self->_url("/$source/$id"),
    sub { $self->$cb($self->_res_from_tx($_[1])); },
  );

  return $self;
}

=head2 patch

  $res = $self->patch($source => $id => \%data);
  $self = $self->patch($source => $id => \%data, $cb);

Used to UPDATE a single record from C<$source>, identified by C<id>.
C<%data> can be partial or full set of column/values.

=cut

sub patch {
  my ($self, $source, $id, $data, $cb) = @_;

  return $self->_blocking(patch => $source, $id, $data) unless ref $cb eq 'CODE';
  return $self->_abort('Invalid source or id.', $cb) unless $source and defined $id;
  return $self->_abort('Invalid data.', $cb) unless ref $data eq 'HASH';

  Scalar::Util::weaken($self);
  $self->_ua->patch(
    $self->_url("/$source/$id"),
    j($data),
    sub { $self->$cb($self->_res_from_tx($_[1])); },
  );

  return $self;
}

=head2 put

  $res = $self->put($source => \%data);
  $self = $self->put($source => \%data, $cb);

Used to INSERT or UPDATE a single row. An UPDATE will be issued if C<%data>
contain an unique constraint a matching record in database.

L</put> v.s L</patch>: L</patch> will never INSERT a new record, while
L</put> will make sure a given record exists.

NOTE: C<%data> without any unique constraints will result in INSERT.

=cut

sub put {
  my ($self, $source, $data, $cb) = @_;

  return $self->_blocking(put => $source, $data) unless ref $cb eq 'CODE';
  return $self->_abort('Invalid source.', $cb) unless $source;
  return $self->_abort('Invalid data.', $cb) unless ref $data eq 'HASH';

  Scalar::Util::weaken($self);
  $self->_ua->put(
    $self->_url("/$source"),
    j($data),
    sub { $self->$cb($self->_res_from_tx($_[1])); },
  );

  return $self;
}

=head2 search

  $res = $self->search($source => \%query, \%extra);
  $self = $self->search($source => \%query, \%extra, $cb);

Does a SELECT from the given C<source> with a given C<%query> and C<%extra>
parameters. This method is very similar to L<DBIx::Class::ResultSet/search>,
but with less C<%extra> options:

=over 4

=item * columns

Only output the given columns. Example:

  $extra{columns} = [qw( id name )];

=item * limit

Used to limit the number of rows in the output.

  $extra{limit} = 10;

=item * page=:int (optional)

Used for pagination when C<limit> is specified.

  $extra{limit} = 2;

=item * order_by

Sort the result by column(s). Examples:

  $extra{order_by} = ["name"];
  $extra{order_by} = { "-desc" => "name" };

=back

=cut

sub search {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self = shift;
  my $source = shift;
  my $query = shift;
  my $extra = shift || {};

  return $self->_blocking(search => $source, $query, $extra) unless ref $cb eq 'CODE';
  return $self->_abort('Invalid source.', $cb) unless $source;
  return $self->_abort('Invalid query.', $cb) unless ref($query) =~ /HASH|ARRAY/;

  $extra->{columns} = j $extra->{columns} if $extra->{columns};
  $extra->{order_by} = j $extra->{order_by} if $extra->{order_by};
  $extra->{q} = j $query;

  Scalar::Util::weaken($self);
  $self->_ua->get(
    $self->_url("/$source/search")->query($extra),
    sub { $self->$cb($self->_res_from_tx($_[1])); },
  );

  return $self;
}

sub _blocking {
  my ($self, $method, @args) = @_;
  my ($err, $res);

  $self->$method(@args, sub {
    my $self = shift;
    ($err, $res) = @_;
    $self->_ua->ioloop->stop;
  });

  $self->_ua->ioloop->start;
  die $err if $err;
  return $res;
}

sub _abort {
  my ($self, $err, $cb) = @_;

  Scalar::Util::weaken($self);
  $self->_ua->ioloop->timer(0, sub { $self and $self->$cb($err) });
  $self;
}

sub _res_from_tx {
  my ($self, $tx) = @_;
  my ($err, $res);

  $res = $tx->res->json;

  if (not ref $res) {
    $err = $tx->error;
    $err = $err->{message} if ref $err;
  }
  elsif ($tx->res->code != 200) {
    $err = $res->{message};
  }

  return $err, $res || {};
}

sub _url {
  $_[0]->url->clone->path($_[1]);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
