package Cookieville::Plugin::Authorize;

=head1 NAME

Cookieville::Plugin::Authorize - Plugin for handling authorization

=head1 DESCRIPTION

L<Cookieville::Plugin::Authorize> is a plugin for just allowing some clients
from doing read/write/update. The clients are identified by the
C<X-Cookieville-Auth-Id> HTTP header. These headers should be long to prevent
brute force entry.

=head1 SYNOPSIS

This L</SYNOPSIS> explains how to enable this plugin in the L<Cookieville> server.

Example C<MOJO_CONFIG> file:

  {
    access_rules => {
      "Some-Long-Auth-Id-12b34acf274" => {
        Artist => [qw( GET PATCH )],
        CD => [qw( GET PATCH PUT )],
      },
    },
  }

The presense of "access_rules" in C<MOJO_CONFIG> file will load this plugin
with the given set of rules.

The rules above will allow a client with the C<X-Cookieville-Auth-Id> header
set to "Some-Long-Auth-Id-12b34acf274" to "GET" and "PATCH" data to the
"Artist" source. The same client can also "GET", "PATCH" and "PUT" data to the "CD"
source.

Any client can access "/".

Any client with a valid C<X-Cookieville-Auth-Id> can access "/sources".

Any other request will result in HTTP status code "401" and an error message.

You can have as many C<X-Cookieville-Auth-Id> keys under "access_rules"
as you want.

=cut

use Mojo::Base 'Mojolicious::Plugin';

=head1 METHODS

=head2 register

This plugin will register a route with the name "cookieville_authorizer" in
the main app. This route is then used for any request in the main app,
except "/".

=cut

sub register {
  my ($self, $app, $rules) = @_;
  my $r = $app->routes->route('/')->bridge;

  $r->name('cookieville_authorizer');
  $r->to(
    cb => sub {
      my $c = shift;
      my $method = $c->req->method;
      my $id = $c->req->headers->header('X-Cookieville-Auth-Id') || '';
      my @path = @{ $c->req->url->path };

      $c->stash(auth_id => $id);

      if (!$id or !$rules->{$id}) {
        $c->render('not_authorized', status => 401);
        return undef;
      }
      if (!@path or $path[0] eq 'sources') {
        return 1;
      }
      if (!$rules->{$id}{$path[0]}) {
        $c->render('not_authorized', message => "No access to $path[0].", status => 401);
        return undef;
      }

      for my $m (@{ $rules->{$id}{$path[0]} || [] }) {
        return 1 if $m eq $method;
      }

      $c->render('not_authorized', message => "Cannot $method $path[0].", status => 401);
      return undef;
    },
  );
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
