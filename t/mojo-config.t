use Mojo::Base -base;
use Test::Mojo;
use Test::More;
use Cookieville;

plan skip_all => 'Could not read t/mojo.conf' unless -r 't/mojo.conf';
$ENV{MOJO_CONFIG} = 't/mojo.conf';

my $t = Test::Mojo->new(Cookieville->new);

{
  is $t->app->inactive_timeout, 1, 'inactive_timeout';
  is $t->app->schema_class, 't::Schema', 'schema_class';
  is_deeply $t->app->connect_args, [ 'dbi:SQLite:dbname=test.sqlite' ], 'connect_args';
}

done_testing;
