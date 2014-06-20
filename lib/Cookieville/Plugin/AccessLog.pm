package Cookieville::Plugin::AccessLog;

=head1 NAME

Cookieville::Plugin::AccessLog - Plugin for logging requests

=head1 DESCRIPTION

L<Cookieville::Plugin::AccessLog> is a plugin that will log any data used to
select, delete, insert or update records in the database. This log will be
written using the default L<log|Mojo/log> object, with "info" log level.

Below you can see an example log created by this plugin:

  [Fri Jun 20 14:39:51 2014] [info] [Anonymous] GET / {} 200
  [Fri Jun 20 14:39:51 2014] [info] [Anonymous] GET /sources {} 401
  [Fri Jun 20 14:39:51 2014] [info] [Some-Invalid-Auth-Id] DELETE /Artist/1 {} 401
  [Fri Jun 20 14:39:51 2014] [info] [Some-Invalid-Auth-Id] PATCH /Artist/1 {} 401
  [Fri Jun 20 14:39:51 2014] [info] [Some-Invalid-Auth-Id] PUT /Artist {} 401
  [Fri Jun 20 14:39:51 2014] [info] [Some-Invalid-Auth-Id] GET /Artist/search {"q" => "{}"} 401
  [Fri Jun 20 14:39:51 2014] [info] [Some-Long-Auth-Id-12b34acf274] GET /sources {} 200
  [Fri Jun 20 14:39:51 2014] [info] [Some-Long-Auth-Id-12b34acf274] DELETE /Artist/1 {} 200
  [Fri Jun 20 14:39:51 2014] [info] [Some-Long-Auth-Id-12b34acf274] PUT /Artist {"name" => "Elvis"} 200
  [Fri Jun 20 14:39:51 2014] [info] [Some-Long-Auth-Id-12b34acf274] PATCH /Artist/1 {"url" => "http://mojolicio.us"} 200
  [Fri Jun 20 14:39:51 2014] [info] [Some-Long-Auth-Id-12b34acf274] GET /Artist/search {"q" => "{}"} 200
  [Fri Jun 20 14:39:51 2014] [info] [Some-Long-Auth-Id-12b34acf274] DELETE /CD/1 {} 401
  [Fri Jun 20 14:39:51 2014] [info] [Some-Long-Auth-Id-12b34acf274] PUT /CD {"name" => "Elvis"} 401
  [Fri Jun 20 14:39:51 2014] [info] [Some-Long-Auth-Id-12b34acf274] PATCH /CD/1 {"url" => "http://mojolicio.us"} 404
  [Fri Jun 20 14:39:51 2014] [info] [Some-Long-Auth-Id-12b34acf274] GET /CD/search {"q" => "{}"} 200

The output is taken from the C<t/plugin-authorize.t> unit test.

THE LOG FORMAT IS CURRENTLY EXPERIMENTAL AND WILL CHANGE WITHOUT ANY NOTICE.

=head1 SYNOPSIS

This L</SYNOPSIS> explains how to enable this plugin in the L<Cookieville> server.

Example C<MOJO_CONFIG> file that will enable this plugin:

  {
    access_log => {},
  }

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Data::Dumper ();
use Time::HiRes qw( gettimeofday tv_interval );

=head1 METHODS

=head2 register

This plugin will register a "before_dispatch" hook which will log on
L<Mojo::Transaction::HTTP> "finish" event.

=cut

sub register {
  my ($self, $app, $config) = @_;

  $app->hook(
    before_dispatch => sub {
      my $c = shift;
      my $t0 = [gettimeofday];

      $c->tx->on(
        finish => sub {
          my $tx = shift;
          my $req = $c->req;
          my $dd = Data::Dumper->new([ $req->json || $req->url->query->to_hash ]);

          $dd->Indent(1)->Indent(0)->Sortkeys(1)->Terse(1)->Useqq(1);

          $app->log->info(
            sprintf '[%s] %s %s %s %s',
            $c->stash('auth_id') || 'Anonymous',
            $req->method,
            $req->url->path,
            $dd->Dump,
            $c->res->code || '000',
          );
        },
      );
    }
  );
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
