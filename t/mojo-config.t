use Mojo::Base -base;
use Test::Mojo;
use Test::More;
use Cookieville;

$ENV{MOJO_CONFIG} = 't/mojo.conf';

plan skip_all => 'Cannot read MOJO_CONFIG' unless -r $ENV{MOJO_CONFIG};

my $t = Test::Mojo->new(Cookieville->new);

{
  is $t->app->inactive_timeout, 1, 'inactive_timeout';
  is $t->app->schema_class, 't::Schema', 'schema_class';
  is_deeply $t->app->connect_args, [ 'dbi:SQLite:dbname=test.sqlite' ], 'connect_args';
}

done_testing;
