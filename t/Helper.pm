package t::Helper;
use Mojo::Base -strict;
use Mojo::Util;
use Cookieville;
use t::Schema;

my $DB_FILE;

sub client {
  my ($class, $t) = @_;
  require Cookieville::Client;
  my $client = Cookieville::Client->new(url => '/');
  $client->_ua($t->ua);
  $client;
}

sub client_cb {
  ($::err, $::res) = ('', undef);

  return sub {
    my $client = shift;
    ($::err, $::res) = @_;
    $client->_ua->ioloop->stop;
  };
}

sub t {
  my $app = Cookieville->new;
  my $t = Test::Mojo->new($app);

  $app->connect_args([ "dbi:SQLite:dbname=$DB_FILE" ]);
  $app->schema_class('t::Schema');
  $app->db->deploy;

  return $t;
}

sub import {
  my $class = shift;
  my $caller = caller;

  $DB_FILE = $0;
  $DB_FILE =~ s!^\W+!!;
  $DB_FILE =~ s!\W!_!g;
  $DB_FILE .= '.sqlite';
  unlink $DB_FILE;

  strict->import;
  warnings->import;

  Mojo::Util::monkey_patch($caller => d => \&Mojo::Util::dumper);

  eval <<"  CODE" or die $@;
    package $caller;
    use Test::Mojo;
    use Test::More;
    1;
  CODE
}

END {
  unlink $DB_FILE if $DB_FILE;
}

1;
