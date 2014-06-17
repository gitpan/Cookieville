package Cookieville;

=head1 NAME

Cookieville - REST API for your database

=head1 VERSION

0.02

=head1 DESCRIPTION

L<Cookieville> is a a web application which allow you to inspect and run
queries on your SQL database using a REST interface.

This application need a L<DBIx::Class> based L<schema|/schema_class> to work.
It will query the result files on disk to gather meta information about the
schema instead of looking into the running database.

THIS SERVER IS CURRENTLY EXPERIMENTAL AND WILL CHANGE WITHOUT ANY NOTICE.

=head1 SYNOPSIS

  $ COOKIEVILLE_SCHEMA="My::Schema" cookieville daemon --listen http://*:5000

Connection arguments will be read from C<$HOME/.cookieville>. Example:

  $ cat $HOME/.cookieville
  {
    'My::Schema' => [
      'DBI:mysql:database=some_database;host=localhost',
      'dr_who',
      'MostS3cretpassWord',
    ],
  }

TIP: Give C<.cookieville> the file mode 0600 to protect your passwords.

It is also possible to specify config file using the C<MOJO_CONFIG>
environment variable. This is also useful for setting up
L<hypnotoad|Mojo::Server::Hypnotoad>:

  $ cat some_config.conf
  {
    inactive_timeout => 10,
    schema_class => 'My::Schema',
    connect_args => {
      'DBI:mysql:database=some_database;host=localhost',
      'dr_who',
      'MostS3cretpassWord',
    },
    hypnotoad => {
      listen => [ 'http://*:5000 ],
      workers => 10,
    },
  }

=head1 RESOURCES

=over 4

=item * GET /

Returns a description of this application:

  {
    "version": "0.01",
    "source": "https://github.com/jhthorsen/cookieville",
    "resources": {
      "schema_source_list": [ "GET", "/sources" ],
      "schema_for_source": [ "GET", "/:source/schema" ],
      "source_search": [ "GET", "/:source/search?q=:json&limit=:int&order_by:json" ],
      "source_delete": [ "DELETE", "/:source/:id" ],
      "source_patch": [ "PATCH", "/:source/:id" ],
      "source_update_or_insert": [ "PUT", "/:source" ]
    }
  }

The environment variable C<COOKIEVILLE_INFO> can be used to limit the data returned:

  COOKIEVILLE_INFO=source,resources

=item * GET /sources

Returns a list of available sources (resultsets). Example:

  [ "Users", "Posts" ]

=item * GET /:source/schema

Returns the schema for the given C<source>.

=item * GET /:source/search

Does a SELECT from the given C<source> with a given set of query params:

=over 4

=item * q=:json (mandatory)

C<q> will be L<deserialized|Mojo::JSON/decode> and used as the
L<query part|/Queries>.

=item * columns=:json (optional)

Only output the given columns. Example:

  columns=["id","name"]

=item * limit=:int (optional)

Used to limit the number of rows in the output.

=item * page=:int (optional)

Used for pagination when C<limit> is specified.

=item * order_by=:json (optional)

Sort the result by column(s). Examples:

  order_by={"-desc","name"}
  order_by=["name","id"]

=back

The return value will be a JSON document containing the rows. Example:

  {
    data: [
      { "id": 1002, "name": "Jan Henning Thorsen", "age": 31 },
      { "id": 3005, "name": "Billy West", "age": 62 }
    ]
  }

TODO: Make sure integers from the database are actual integers in the
result JSON.

The format L<.csv|http://en.wikipedia.org/wiki/Comma-separated_values> is
also supported. Example:

  GET /Users.csv?q={"age":31}&order_by=name

=item * DELETE /:source/:id

Used to DELETE a single row identified by C<id>.

The return value will be a JSON document with the number of rows deleted:

  {"n":1}

NOTE: This will be C<{"n":0}> if the record was already deleted.

=item * PATCH /:source/:id

Used to do a (partial) UPDATE of a single row identified by C<id>. The HTTP
body must be a JSON structure with the data to update to.

The return value will have the new document. Example:

  {
    "data": { "id": 1002, "name": "Jan Henning Thorsen", "age": 31 }
  }

Will return 404 if the given C<id> does not match any records in the database.

=item * PUT /:source

Used to INSERT or UPDATE a single row. The HTTP body must be a JSON
structure with the data to insert or update.

The return value will be a JSON document containing all the data for the
inserted or updated row. Example:

  {
    "inserted": true, # or false
    "data": { "id": 1002, "name": "Jan Henning Thorsen", "age": 31 }
  }

=back

=head2 Error handling

The API will return "200 OK" on success and another error code on failure:

=over 4

=item * 400

Return the document below on invalid input data. C<message> holds a
description of what is missing. Example:

  { "message": "Missing (q) query param." }

=item * 401

Return the document below on when not authorized. C<message> holds a
description of why not. Example:

  { "message": "Invalid token." }

=item * 404

Return the document below if the given resource could not be found.
C<message> holds a description of what is not found. Examples:

  { "message": "Resource not found" }
  { "message": "No source by that name." }
  { "message": "No matching records in database." }

=item * 500

  { "message": "Internal server error." }

Generic error when something awful happens. C<message> might not make any
sense. Look at the server log for more details.

=back

Other error codes might be added in future releases.

=head2 Queries

The queries (referred to as the "q" query param in the API) are passed on as
the first argument to L<DBIx::Class/search>.

=cut

use Mojo::Base 'Mojolicious';
use File::HomeDir ();
use File::Spec ();

our $VERSION = '0.02';

=head1 ATTRIBUTES

=head2 inactive_timeout

  $int = $self->inactive_timeout;

Used to set the number of seconds before a query agains the database time out.
Defaults to value from config, the environment variable
C<COOKIEVILLE_INACTIVE_TIMEOUT> or 10 seconds.

=head2 connect_args

  $array_ref = $self->connect_args;

Looks in C<$HOME/.cookieville> to find connect args for L</schema_class>.
See L</SYNOPSIS> for details.

=head2 schema_class

  $class_name = $self->schema_class;

Returns the class name used to connect to the database. This defaults to
the environment variable C<COOKIEVILLE_SCHEMA>.

=cut

has inactive_timeout => sub {
  $ENV{COOKIEVILLE_INACTIVE_TIMEOUT} || shift->config('inactive_timeout') || 10;
};

has connect_args => sub {
  my $self = shift;
  my $config_file = File::Spec->catfile(File::HomeDir->my_home, '.cookieville');

  unless(-r $config_file) {
    return $self->config('connect_args') if $self->config('connect_args');
    $self->log->debug("Could not read $config_file");
    return [];
  }

  $config_file = do $config_file or die $@;
  $self->log->debug("Looking for @{[$self->schema_class]} in $config_file");
  return $config_file->{$self->schema_class} || [];
};

has schema_class => sub {
  $ENV{COOKIEVILLE_SCHEMA} || shift->config('schema_class') || '';
};

=head1 HELPERS

=head2 db

  $obj = $self->db;

Returns an instance of L</schema_class>.

=head1 METHODS

=head2 setup_routes

Used to setup the L</RESOURCES>.

=cut

sub setup_routes {
  my $self = shift;
  my $r = $self->routes;

  $r->get('/')->to('schema#index')->name('cookieville') unless $r->find('cookieville');
  $r->get('/sources')->to('schema#sources_list')->name('schema_source_list') unless $r->find('schema_source_list');
  $r->get('/:source/schema')->to('schema#source_schema')->name('schema_for_source') unless $r->find('schema_for_source');
  $r->get('/:source/search')->to('read#search')->name('source_search') unless $r->find('source_search');
  $r->delete('/:source/:id')->to('write#delete')->name('source_delete') unless $r->find('source_delete');
  $r->patch('/:source/:id')->to('write#patch')->name('source_patch') unless $r->find('source_patch');
  $r->put('/:source')->to('write#update_or_insert')->name('source_update_or_insert') unless $r->find('source_update_or_insert');
}

=head2 startup

Will set up L</RESOURCES> and add L</HELPERS>.

=cut

sub startup {
  my $self = shift;

  if ($ENV{MOJO_CONFIG}) {
    $self->plugin('config');
  }
  if (my $schema_class = $self->schema_class) {
    eval "require $schema_class;1" or die $@;
  }

  $self->hook(before_dispatch => sub {
    my $c = shift;
    Mojo::IOLoop->stream($c->tx->connection)->timeout($self->inactive_timeout);
  });

  push @{ $self->renderer->classes }, __PACKAGE__;
  $self->defaults(format => 'json', message => '');
  $self->types->type(csv => 'text/csv');
  $self->helper(db => sub { shift->stash->{db} ||= $self->schema_class->connect(@{ $self->connect_args }); });
  $self->helper(j => sub { Mojo::JSON->new->encode($_[1]); });
  $self->setup_routes;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;

__DATA__
@@ not_found.csv.ep
%= $message || 'Not found.'
@@ not_found.json.ep
%== j { message => $message || 'Not found.' }
@@ not_found.txt.ep
%= $message || 'Not found.'
@@ exception.csv.ep
%= $message || 'Internal server error.'
@@ exception.json.ep
%== j { message => $message || 'Internal server error.' }
@@ exception.txt.ep
%= $message || 'Internal server error.'
